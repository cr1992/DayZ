// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:typed_data';

import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components.dart';
import '../shell/app_router.dart';
import '../theme/dayz_text_theme.dart';
import '../theme/dayz_tokens.g.dart';
import 'reader_body.dart';
import 'reader_controller.dart';
import 'reader_image.dart';
import 'reader_meta.dart';
import 'reader_view_data.dart';

typedef ReaderDataLoader = Future<ReaderViewData?> Function(String entryId);
typedef ReaderImageProviderBuilder =
    ImageProvider Function(ReaderMediaViewData media);

/// Single-entry reader screen.
///
/// Author: @Ray
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.entryId,
    required this.repository,
    required this.loadData,
    this.thumbnailCache,
    this.imageProviderFor = _defaultImageProvider,
    this.onBack,
    this.onEdit,
  });

  static const loadingKey = ValueKey<String>('reader-loading');
  static const heroKey = ValueKey<String>('reader-hero');
  static const kickerKey = ReaderMeta.kickerKey;
  static const titleKey = ValueKey<String>('reader-title');
  static const metaKey = ReaderMeta.metaWrapKey;
  static const bodyKey = ValueKey<String>('reader-body');
  static const galleryKey = ValueKey<String>('reader-gallery');
  static const tagsKey = ReaderMeta.tagsWrapKey;

  final String entryId;
  final ReaderRepository repository;
  final ReaderDataLoader loadData;
  final ReaderThumbnailCache? thumbnailCache;
  final ReaderImageProviderBuilder imageProviderFor;
  final VoidCallback? onBack;
  final ValueChanged<String>? onEdit;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<ReaderViewData?> _dataFuture;
  ReaderController? _controller;

  @override
  void initState() {
    super.initState();
    _dataFuture = widget.loadData(widget.entryId);
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entryId != widget.entryId ||
        oldWidget.loadData != widget.loadData) {
      _controller?.dispose();
      _controller = null;
      _dataFuture = widget.loadData(widget.entryId);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReaderViewData?>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(key: ReaderScreen.loadingKey),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return _ReaderEmptyState(onBack: _goBack);
        }

        final controller = _controller ??= ReaderController(
          data: data,
          repository: widget.repository,
        );
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return _ReaderLoadedScreen(
              controller: controller,
              thumbnailCache: widget.thumbnailCache,
              imageProviderFor: widget.imageProviderFor,
              onBack: _goBack,
              onEdit: widget.onEdit,
            );
          },
        );
      },
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.onBack?.call();
  }
}

class _ReaderLoadedScreen extends StatelessWidget {
  const _ReaderLoadedScreen({
    required this.controller,
    required this.imageProviderFor,
    required this.onBack,
    required this.onEdit,
    this.thumbnailCache,
  });

  final ReaderController controller;
  final ReaderThumbnailCache? thumbnailCache;
  final ReaderImageProviderBuilder imageProviderFor;
  final VoidCallback onBack;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final l10n = AppLocalizations.of(context);
    final feedback = _WidgetReaderFeedback(context: context, onBack: onBack);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          DayzGlassAppBar(
            title: Text(l10n.reader),
            leading: IconButton(
              tooltip: l10n.close,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            actions: [
              DayzFavoriteStar(
                isFavorite: controller.favorite,
                onPressed: () {
                  unawaited(controller.toggleFavorite(l10n, feedback));
                },
              ),
              Semantics(
                button: true,
                label: l10n.readerActionsSemantic,
                child: IconButton(
                  tooltip: l10n.readerActionsSemantic,
                  onPressed: () => _showActions(context, l10n, feedback),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DayzSpacing.s5,
                  DayzSpacing.s4,
                  DayzSpacing.s5,
                  DayzSpacing.s10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.cover != null) ...[
                      _ReaderHero(
                        media: data.cover!,
                        thumbnailCache: thumbnailCache,
                        imageProviderFor: imageProviderFor,
                      ),
                      const SizedBox(height: DayzSpacing.s6),
                    ],
                    ReaderKicker(data: data),
                    const SizedBox(height: DayzSpacing.s3),
                    Text(
                      data.title,
                      key: ReaderScreen.titleKey,
                      style: context.dayzText.h1,
                    ),
                    if (ReaderMetaDetails.hasContent(data)) ...[
                      const SizedBox(height: DayzSpacing.s3),
                      ReaderMetaDetails(data: data),
                    ],
                    const SizedBox(height: DayzSpacing.s5),
                    KeyedSubtree(
                      key: ReaderScreen.bodyKey,
                      child: ReaderBody(paragraphs: data.bodyParagraphs),
                    ),
                    if (data.galleryImages.isNotEmpty) ...[
                      const SizedBox(height: DayzSpacing.s5),
                      DayzGallery(
                        key: ReaderScreen.galleryKey,
                        images: [
                          for (final image in data.galleryImages)
                            imageProviderFor(image),
                        ],
                        expanded: controller.galleryExpanded,
                        onMoreTap: controller.toggleGalleryExpanded,
                      ),
                    ],
                    if (data.tags.isNotEmpty) ...[
                      const SizedBox(height: DayzSpacing.s5),
                      ReaderTags(data: data),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(
    BuildContext context,
    AppLocalizations l10n,
    ReaderFeedback feedback,
  ) {
    DayzSheet.actions<void>(
      context,
      items: [
        for (final item in controller.actionMenuItems(l10n))
          if (item.type == ReaderActionMenuItemType.separator)
            const DayzSheetItem.sep()
          else
            DayzSheetItem(
              label: item.label,
              tone: item.tone,
              onTap: () => _handleAction(item.type, context, l10n, feedback),
            ),
      ],
    );
  }

  void _handleAction(
    ReaderActionMenuItemType type,
    BuildContext context,
    AppLocalizations l10n,
    ReaderFeedback feedback,
  ) {
    switch (type) {
      case ReaderActionMenuItemType.edit:
        final edit = onEdit;
        if (edit != null) {
          edit(controller.entryId);
        } else {
          context.pushNamed(Routes.editor, extra: controller.entryId);
        }
      case ReaderActionMenuItemType.share:
        controller.share(l10n, feedback);
      case ReaderActionMenuItemType.moveToJournal:
        unawaited(controller.moveToJournal(l10n, feedback));
      case ReaderActionMenuItemType.favorite:
        unawaited(controller.toggleFavorite(l10n, feedback));
      case ReaderActionMenuItemType.delete:
        unawaited(controller.delete(l10n, feedback));
      case ReaderActionMenuItemType.separator:
        break;
    }
  }
}

class _ReaderHero extends StatelessWidget {
  const _ReaderHero({
    required this.media,
    required this.imageProviderFor,
    this.thumbnailCache,
  });

  final ReaderMediaViewData media;
  final ReaderThumbnailCache? thumbnailCache;
  final ReaderImageProviderBuilder imageProviderFor;

  @override
  Widget build(BuildContext context) {
    final cache = thumbnailCache;
    return ClipRRect(
      key: ReaderScreen.heroKey,
      borderRadius: BorderRadius.circular(DayzRadii.lg),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: cache == null
            ? Image(image: imageProviderFor(media), fit: BoxFit.cover)
            : ReaderImage(mediaId: media.id, thumbnailCache: cache),
      ),
    );
  }
}

class _ReaderEmptyState extends StatelessWidget {
  const _ReaderEmptyState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.close,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: DayzEmptyState(
          title: l10n.readerEmptyTitle,
          description: l10n.readerEmptyDescription,
        ),
      ),
    );
  }
}

class _WidgetReaderFeedback implements ReaderFeedback {
  const _WidgetReaderFeedback({required this.context, required this.onBack});

  final BuildContext context;
  final VoidCallback onBack;

  @override
  Future<bool> confirmDelete(ReaderDeletePrompt prompt) async {
    final result = await DayzSheet.confirm(
      context,
      title: prompt.title,
      desc: prompt.message,
      primaryLabel: prompt.confirmLabel,
    );
    return result ?? false;
  }

  @override
  void closeReader() {
    onBack();
  }

  @override
  Future<ReaderJournalRecord?> pickJournal(ReaderJournalPrompt prompt) async {
    ReaderJournalRecord? selected;
    await DayzSheet.picker<void>(
      context,
      items: [
        for (final journal in prompt.journals)
          DayzSheetItem(
            label: journal.name,
            desc: AppLocalizations.of(context).entryCount(journal.entryCount),
            selected: journal.id == prompt.currentJournalId,
            onTap: () {
              selected = journal;
            },
          ),
      ],
    );
    return selected;
  }

  @override
  void showToast(ReaderToastEvent event) {
    final action = event.action;
    DayzToast.show(
      context,
      event.text,
      event.tone,
      action == null
          ? null
          : DayzToastAction(
              label: action.label,
              onPressed: () {
                unawaited(action.onPressed());
              },
            ),
    );
  }
}

ImageProvider _defaultImageProvider(ReaderMediaViewData media) {
  return _transparentImageProvider;
}

final ImageProvider _transparentImageProvider = MemoryImage(
  Uint8List.fromList(_transparentPixelPng),
);

const _transparentPixelPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
