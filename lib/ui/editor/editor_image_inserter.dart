// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:typed_data';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'package:dayz/editor/contract/block_types.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';

typedef EditorImageAssetPicker =
    Future<List<EditorPickedImage>> Function(
      BuildContext context,
      AssetPickerConfig config,
    );

class EditorPickedImage {
  EditorPickedImage._({
    required this.name,
    required this.sourcePath,
    required this.width,
    required this.height,
    required this._readBytes,
    this._mime,
    this._loadMime,
    this._cleanup,
  });

  factory EditorPickedImage.memory({
    required Uint8List bytes,
    required String name,
    String? sourcePath,
    String? mime,
    int? width,
    int? height,
  }) {
    return EditorPickedImage._(
      name: name,
      sourcePath: sourcePath,
      width: width,
      height: height,
      mime: mime,
      readBytes: () async => bytes,
    );
  }

  factory EditorPickedImage.xFile(XFile file) {
    return EditorPickedImage._(
      name: file.name,
      sourcePath: file.path,
      width: null,
      height: null,
      mime: file.mimeType,
      readBytes: file.readAsBytes,
      cleanup: () async {
        try {
          final physicalFile = File(file.path);
          if (await physicalFile.exists()) {
            await physicalFile.delete();
          }
        } catch (_) {
          // Ignore cleanup error if the picker file is read-only or ephemeral.
        }
      },
    );
  }

  factory EditorPickedImage.asset(AssetEntity asset) {
    return EditorPickedImage._(
      name: asset.title ?? asset.id,
      sourcePath: asset.relativePath,
      width: asset.orientatedWidth,
      height: asset.orientatedHeight,
      mime: asset.mimeType,
      loadMime: () => asset.mimeTypeAsync,
      readBytes: () async {
        final originBytes = await asset.originBytes;
        if (originBytes != null) {
          return originBytes;
        }
        final file = await asset.originFile ?? await asset.file;
        if (file != null) {
          return file.readAsBytes();
        }
        throw StateError('Unable to read picked image asset: ${asset.id}');
      },
    );
  }

  final String name;
  final String? sourcePath;
  final int? width;
  final int? height;
  final String? _mime;
  final Future<String?> Function()? _loadMime;
  final Future<Uint8List> Function() _readBytes;
  final Future<void> Function()? _cleanup;
  int _cleanupCount = 0;

  int get cleanupCount => _cleanupCount;

  Future<Uint8List> readBytes() {
    return _readBytes();
  }

  Future<String> resolveMime() async {
    return _mime ??
        await _loadMime?.call() ??
        _mimeTypeFromPath(name) ??
        _mimeTypeFromPath(sourcePath ?? '') ??
        'image/jpeg';
  }

  Future<void> cleanupPlainSource() async {
    await _cleanup?.call();
    _cleanupCount += 1;
  }
}

class EditorImageInserter {
  static Future<void> pickAndInsert({
    required BuildContext context,
    required EditorState editorState,
    required dynamic mediaStore,
    required String? entryId,
    EditorImageAssetPicker? pickAssetsOp,
    Future<XFile?> Function()? pickImageOp,
  }) async {
    // Save selection synchronously before focus is lost during picking
    final selection = editorState.selection;
    if (selection == null) return;

    final config = _pickerConfig(context);
    final images = pickAssetsOp != null
        ? await pickAssetsOp(context, config)
        : pickImageOp != null
        ? await _pickLegacySingleImage(pickImageOp)
        : await _pickWechatAssets(context, config);

    if (images.isEmpty) return;

    // Use default entry placeholder if none provided.
    final effectiveEntryId = entryId ?? 'temp-entry';
    final path = selection.start.path;
    final parentPath = path.sublist(0, path.length - 1);

    final transaction = editorState.transaction;
    // Every image inserts at the same sibling index. Transaction.add auto-
    // transforms each subsequent InsertOperation (+1) against the prior ones,
    // so they land contiguously right after the selection. Adding a manual
    // `+ i` here would stack with that transform and double-shift the paths,
    // interleaving the original following nodes between the images everywhere
    // except at end-of-document.
    final insertPath = [...parentPath, path.last + 1];
    for (var i = 0; i < images.length; i += 1) {
      final image = images[i];
      final bytes = await image.readBytes();
      final relPath = await mediaStore.put(
        bytes: Stream<List<int>>.value(bytes),
        entryId: effectiveEntryId,
        kind: MediaKind.image,
        mime: await image.resolveMime(),
        width: image.width,
        height: image.height,
        fileSize: bytes.length,
      );
      await image.cleanupPlainSource();

      // Extract media.id from relPath (e.g. 'media/media-1.bin' -> 'media-1').
      final mediaId = relPath.split('/').last.split('.').first;
      final node = Node(
        type: ImageBlockKeys.type,
        attributes: {
          ImageBlockKeys.url: EditorImageReference.urlForMediaId(mediaId),
        },
      );
      transaction.insertNode(insertPath, node);
    }
    await editorState.apply(transaction);
    // The N images now occupy [path.last + 1 .. path.last + images.length];
    // collapse the caret onto the last one.
    editorState.selection = Selection.collapsed(
      Position(path: [...parentPath, path.last + images.length], offset: 0),
    );
  }
}

AssetPickerConfig _pickerConfig(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return AssetPickerConfig(
    maxAssets: 9,
    gridCount: 4,
    requestType: RequestType.image,
    themeColor: context.dayz.accent,
    textDelegate: _DayzAssetPickerTextDelegate(
      locale: Localizations.localeOf(context),
      confirm: l10n.editorImagePickerDone,
      cancel: l10n.editorImagePickerCancel,
      original: l10n.editorImagePickerOriginal,
      preview: l10n.editorImagePickerPreview,
      camera: l10n.editorImagePickerCamera,
    ),
    pathNameBuilder: (path) =>
        path.isAll ? l10n.editorImagePickerAllPhotos : path.name,
    specialItems: [
      SpecialItem<AssetPathEntity>(
        position: SpecialItemPosition.prepend,
        builder: (context, _, _) =>
            _CameraGridItem(semanticLabel: l10n.editorImagePickerCamera),
      ),
    ],
  );
}

Future<List<EditorPickedImage>> _pickLegacySingleImage(
  Future<XFile?> Function() pickImageOp,
) async {
  final image = await pickImageOp();
  if (image == null) return const <EditorPickedImage>[];
  return [EditorPickedImage.xFile(image)];
}

Future<List<EditorPickedImage>> _pickWechatAssets(
  BuildContext context,
  AssetPickerConfig config,
) async {
  final assets = await AssetPicker.pickAssets(context, pickerConfig: config);
  if (assets == null || assets.isEmpty) {
    return const <EditorPickedImage>[];
  }
  return assets.map(EditorPickedImage.asset).toList(growable: false);
}

class _DayzAssetPickerTextDelegate extends AssetPickerTextDelegate {
  const _DayzAssetPickerTextDelegate({
    required this._locale,
    required this.confirm,
    required this.cancel,
    required this.original,
    required this.preview,
    required this.camera,
  });

  final Locale _locale;
  @override
  final String confirm;
  @override
  final String cancel;
  @override
  final String original;
  @override
  final String preview;
  final String camera;

  @override
  String get languageCode => _locale.languageCode;

  @override
  String? get scriptCode => _locale.scriptCode;

  @override
  String? get countryCode => _locale.countryCode;

  @override
  String get sActionUseCameraHint => camera;
}

class _CameraGridItem extends StatelessWidget {
  const _CameraGridItem({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: () => _pickFromCamera(context),
          child: Icon(
            Icons.camera_alt_outlined,
            color: theme.colorScheme.onSurface,
            size: 28,
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final shot = await ImagePicker().pickImage(source: ImageSource.camera);
    if (shot == null) return;
    final asset = await PhotoManager.editor.saveImageWithPath(
      shot.path,
      title: shot.name,
    );
    if (context.mounted) {
      Navigator.of(context).pop(<AssetEntity>[asset]);
    }
  }
}

String? _mimeTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}
