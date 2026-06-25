// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dayz/editor/contract/block_types.dart' as dayz_blocks;
import 'package:dayz/gen/assets.gen.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/editor/editor_image_inserter.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

void main() {
  setUpAll(() async {
    await AppFlowyEditorLocalizations.load(
      const Locale.fromSubtags(languageCode: 'zh'),
    );
  });

  patrolTest('editor image picker selects a photo and inserts media node', (
    $,
  ) async {
    final mediaRepo = _PatrolMediaRepo();
    final mediaStore = _PatrolMediaStore(mediaRepo: mediaRepo);
    final editorState = EditorState(
      document: Document(
        root: pageNode(children: [paragraphNode(text: 'hello')]),
      ),
    );
    editorState.selection = Selection.collapsed(Position(path: [0], offset: 5));
    addTearDown(editorState.dispose);

    await $.pumpWidgetAndSettle(
      _ImagePickerHarness(editorState: editorState, mediaStore: mediaStore),
    );

    final permission = await _grantPhotoLibraryAccess($);
    expect(permission.hasAccess, isTrue);
    final seededAsset = await _seedPhotoLibraryImage();
    $.log('Seeded photo asset for picker: ${seededAsset.id}');

    final insertFuture = EditorImageInserter.pickAndInsert(
      context: $.tester.element(
        find.byKey(const ValueKey<String>('openImagePicker')),
      ),
      editorState: editorState,
      mediaStore: mediaStore,
      entryId: 'patrol-entry',
    );
    var insertCompleted = false;
    Object? insertError;
    unawaited(
      insertFuture
          .then<void>((_) {
            insertCompleted = true;
          })
          .catchError((Object error) {
            insertCompleted = true;
            insertError = error;
          }),
    );
    await $.pumpAndSettle();

    final assetTile = find.byType(AssetEntityGridItemBuilder);
    final pickerReady = await _pumpUntilVisible(
      $.tester,
      assetTile,
      timeout: const Duration(seconds: 12),
    );
    if (!pickerReady) {
      $.log(
        'Picker debug: insertCompleted=$insertCompleted '
        'insertError=$insertError '
        'assetTiles=${find.byType(AssetEntityGridItemBuilder).evaluate().length} '
        'texts=${_textSnapshot()}',
      );
    }
    expect(pickerReady, isTrue);
    expect(find.text('预览'), findsWidgets);
    expect(find.textContaining('完成'), findsWidgets);
    expect(find.textContaining('最近项目'), findsWidgets);
    expect(find.bySemanticsLabel('拍照'), findsWidgets);
    final tileRect = $.tester.getRect(assetTile.first);
    await $.tester.tapAt(Offset(tileRect.right - 12, tileRect.top + 12));
    await $.pumpAndSettle();

    expect(
      await _pumpUntilVisible(
        $.tester,
        find.textContaining('完成 (1/9)'),
        timeout: const Duration(seconds: 4),
      ),
      isTrue,
    );
    await $.tester.tap(find.textContaining('完成').last);
    await $.pumpAndSettle();

    expect(
      await _pumpUntil(
        $.tester,
        () => mediaStore.putCalls.isNotEmpty && mediaRepo.addedIds.isNotEmpty,
        timeout: const Duration(seconds: 12),
      ),
      isTrue,
    );
    await insertFuture.timeout(const Duration(seconds: 4));

    expect(mediaStore.putCalls, hasLength(1));
    expect(mediaStore.putCalls.single.entryId, 'patrol-entry');
    expect(mediaStore.putCalls.single.mime, startsWith('image/'));
    expect(mediaStore.putCalls.single.fileSize, greaterThan(0));
    expect(mediaRepo.addedIds, ['patrol-media-1']);
    expect(
      editorState.document.root.children
          .where((node) => node.type == dayz_blocks.EditorBlockTypes.image)
          .map((node) => node.attributes[ImageBlockKeys.url]),
      contains('dayz-media://patrol-media-1'),
    );
  });
}

Future<PermissionState> _grantPhotoLibraryAccess(
  PatrolIntegrationTester $,
) async {
  final permissionFuture = PhotoManager.requestPermissionExtend();
  final existingPermission = await permissionFuture.timeout(
    const Duration(milliseconds: 800),
    onTimeout: () => PermissionState.notDetermined,
  );
  if (existingPermission != PermissionState.notDetermined) {
    return existingPermission;
  }
  await _tapFullPhotoAccess($);
  return permissionFuture;
}

Future<void> _tapFullPhotoAccess(PatrolIntegrationTester $) async {
  try {
    await $.platformAutomator.mobile.grantPermissionOnlyThisTime();
    return;
  } catch (_) {
    // iOS 26 Chinese simulators are not covered by Patrol's bundled
    // permission localizations yet; use localized selectors and coordinates.
  }

  const springBoardBundleId = 'com.apple.springboard';
  final selectors = <CompoundSelector>[
    IOSSelector(elementType: IOSElementType.button, label: '允许完全访问'),
    IOSSelector(elementType: IOSElementType.button, labelContains: '完全访问'),
    IOSSelector(elementType: IOSElementType.button, label: 'Allow Full Access'),
    IOSSelector(
      elementType: IOSElementType.button,
      labelContains: 'Full Access',
    ),
  ];

  for (final selector in selectors) {
    try {
      await $.platformAutomator.tap(
        selector,
        appId: springBoardBundleId,
        timeout: const Duration(seconds: 1),
      );
      return;
    } catch (_) {
      // Try the next localized system button.
    }
  }

  await $.platformAutomator.mobile.tapAt(
    const Offset(0.5, 0.67),
    appId: springBoardBundleId,
  );
}

Future<AssetEntity> _seedPhotoLibraryImage() async {
  final data = await rootBundle.load(Assets.editor.demoImage.path);
  return PhotoManager.editor.saveImage(
    data.buffer.asUint8List(),
    filename: 'dayz_s1_patrol.png',
    title: 'dayz_s1_patrol_${DateTime.now().microsecondsSinceEpoch}.png',
    creationDate: DateTime.now(),
  );
}

Future<bool> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) {
  return _pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    timeout: timeout,
  );
}

Future<bool> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (condition()) {
      return true;
    }
  }
  return false;
}

String _textSnapshot() {
  final values = find
      .byType(Text)
      .evaluate()
      .map((element) => element.widget)
      .whereType<Text>()
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((text) => text.isNotEmpty)
      .take(20)
      .join(' | ');
  return values.isEmpty ? '<none>' : values;
}

class _ImagePickerHarness extends StatelessWidget {
  const _ImagePickerHarness({
    required this.editorState,
    required this.mediaStore,
  });

  final EditorState editorState;
  final _PatrolMediaStore mediaStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: DayzThemes.purpleLight,
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const ValueKey<String>('openImagePicker'),
                onPressed: () {
                  EditorImageInserter.pickAndInsert(
                    context: context,
                    editorState: editorState,
                    mediaStore: mediaStore,
                    entryId: 'patrol-entry',
                  );
                },
                child: const Text('打开图片选择器'),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PatrolMediaStore {
  _PatrolMediaStore({required this.mediaRepo});

  final _PatrolMediaRepo mediaRepo;
  final putCalls = <_PatrolPutCall>[];
  int _nextId = 1;

  Future<String> put({
    required Stream<List<int>> bytes,
    required String entryId,
    required dynamic kind,
    required String mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    final id = 'patrol-media-${_nextId++}';
    final relPath = 'media/$id.bin';
    await bytes.drain<void>();
    putCalls.add(
      _PatrolPutCall(
        id: id,
        entryId: entryId,
        mime: mime,
        width: width,
        height: height,
        durationMs: durationMs,
        fileSize: fileSize,
      ),
    );
    await mediaRepo.addMeta(
      id,
      entryId,
      '$kind',
      relPath,
      mime: mime,
      width: width,
      height: height,
      durationMs: durationMs,
      fileSize: fileSize,
    );
    return relPath;
  }
}

class _PatrolPutCall {
  const _PatrolPutCall({
    required this.id,
    required this.entryId,
    required this.mime,
    this.width,
    this.height,
    this.durationMs,
    this.fileSize,
  });

  final String id;
  final String entryId;
  final String mime;
  final int? width;
  final int? height;
  final int? durationMs;
  final int? fileSize;
}

class _PatrolMediaRepo {
  final addedIds = <String>[];

  Future<void> addMeta(
    String id,
    String entryId,
    String kind,
    String relPath, {
    required String mime,
    int? width,
    int? height,
    int? durationMs,
    int? fileSize,
  }) async {
    addedIds.add(id);
  }
}
