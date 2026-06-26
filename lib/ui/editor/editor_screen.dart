// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/editor/contract/editor_doc_codec.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_button.dart';
import 'package:dayz/ui/widgets/dayz_icon.dart';
import 'package:dayz/ui/widgets/dayz_icons.dart';

import 'editor_meta_bar.dart';
import 'editor_style.dart';
import 'editor_toolbar.dart';
import 'editor_draft_bridge.dart';
import 'editor_image_inserter.dart';

enum EditorScreenMode { empty, writing, rich }

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.mode,
    required this.entryDate,
    this.title,
    this.bodyPreview,
    this.onClose,
    this.onDone,
    this.entryId,
    this.draftCoordinator,
    this.entryRepo,
    this.mediaStore,
    this.mediaRepo,
    this.pickImageOp,
    this.initialContentJson,
  });

  const EditorScreen.empty({
    Key? key,
    required DateTime entryDate,
    VoidCallback? onClose,
    VoidCallback? onDone,
    String? entryId,
    dynamic draftCoordinator,
    dynamic entryRepo,
    dynamic mediaStore,
    dynamic mediaRepo,
    Future<XFile?> Function()? pickImageOp,
    String? initialContentJson,
  }) : this(
         key: key,
         mode: EditorScreenMode.empty,
         entryDate: entryDate,
         onClose: onClose,
         onDone: onDone,
         entryId: entryId,
         draftCoordinator: draftCoordinator,
         entryRepo: entryRepo,
         mediaStore: mediaStore,
         mediaRepo: mediaRepo,
         pickImageOp: pickImageOp,
         initialContentJson: initialContentJson,
       );

  const EditorScreen.writing({
    Key? key,
    required DateTime entryDate,
    String? title,
    String? bodyPreview,
    VoidCallback? onClose,
    VoidCallback? onDone,
    String? entryId,
    dynamic draftCoordinator,
    dynamic entryRepo,
    dynamic mediaStore,
    dynamic mediaRepo,
    Future<XFile?> Function()? pickImageOp,
    String? initialContentJson,
  }) : this(
         key: key,
         mode: EditorScreenMode.writing,
         entryDate: entryDate,
         title: title,
         bodyPreview: bodyPreview,
         onClose: onClose,
         onDone: onDone,
         entryId: entryId,
         draftCoordinator: draftCoordinator,
         entryRepo: entryRepo,
         mediaStore: mediaStore,
         mediaRepo: mediaRepo,
         pickImageOp: pickImageOp,
         initialContentJson: initialContentJson,
       );

  const EditorScreen.rich({
    Key? key,
    required DateTime entryDate,
    String? title,
    String? bodyPreview,
    VoidCallback? onClose,
    VoidCallback? onDone,
    String? entryId,
    dynamic draftCoordinator,
    dynamic entryRepo,
    dynamic mediaStore,
    dynamic mediaRepo,
    Future<XFile?> Function()? pickImageOp,
    String? initialContentJson,
  }) : this(
         key: key,
         mode: EditorScreenMode.rich,
         entryDate: entryDate,
         title: title,
         bodyPreview: bodyPreview,
         onClose: onClose,
         onDone: onDone,
         entryId: entryId,
         draftCoordinator: draftCoordinator,
         entryRepo: entryRepo,
         mediaStore: mediaStore,
         mediaRepo: mediaRepo,
         pickImageOp: pickImageOp,
         initialContentJson: initialContentJson,
       );

  static const Key closeButtonKey = ValueKey<String>('editor-close-button');
  static const Key doneButtonKey = ValueKey<String>('editor-done-button');
  static const Key titleFieldKey = ValueKey<String>('editor-title-field');
  static const Key bodyPlaceholderKey = ValueKey<String>(
    'editor-body-placeholder',
  );

  final EditorScreenMode mode;
  final DateTime entryDate;
  final String? title;
  final String? bodyPreview;
  final VoidCallback? onClose;
  final VoidCallback? onDone;
  final String? entryId;
  final dynamic draftCoordinator;
  final dynamic entryRepo;
  final dynamic mediaStore;
  final dynamic mediaRepo;
  final Future<XFile?> Function()? pickImageOp;
  final String? initialContentJson;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _titleController;
  late EditorState _editorState;
  EditorDraftBridge? _draftBridge;
  bool _hasDraftSaved = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _editorState = _createEditorState(widget);

    final coord = widget.draftCoordinator;
    if (coord != null) {
      _draftBridge = EditorDraftBridge(
        editorState: _editorState,
        draftCoordinator: coord,
        targetId: widget.entryId,
        isNew: widget.mode == EditorScreenMode.empty,
        onFirstDraftFlushed: () {
          if (!_hasDraftSaved && mounted) {
            setState(() {
              _hasDraftSaved = true;
            });
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title &&
        _titleController.text != (widget.title ?? '')) {
      _titleController.text = widget.title ?? '';
    }
    if (oldWidget.mode != widget.mode ||
        oldWidget.bodyPreview != widget.bodyPreview ||
        oldWidget.initialContentJson != widget.initialContentJson) {
      final previous = _editorState;
      _editorState = _createEditorState(widget);
      _draftBridge?.dispose();
      final coord = widget.draftCoordinator;
      if (coord != null) {
        _draftBridge = EditorDraftBridge(
          editorState: _editorState,
          draftCoordinator: coord,
          targetId: widget.entryId,
          isNew: widget.mode == EditorScreenMode.empty,
          onFirstDraftFlushed: () {
            if (!_hasDraftSaved && mounted) {
              setState(() {
                _hasDraftSaved = true;
              });
            }
          },
        );
      }
      previous.dispose();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _draftBridge?.dispose();
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;

    final mainContent = CustomScrollView(
      slivers: [
        DayzGlassAppBar(
          centerTitle: true,
          leading: DayzButton.icon(
            key: EditorScreen.closeButtonKey,
            icon: DayzIcon.path(
              DayzIcons.closePath,
              size: 24,
              color: colors.ink2,
            ),
            semanticLabel: l10n.editorCloseSemanticLabel,
            variant: DayzButtonVariant.text,
            onPressed: _handleClose,
          ),
          title: Text(_navTitle(l10n)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: DayzSpacing.s3),
              child: Semantics(
                key: EditorScreen.doneButtonKey,
                button: true,
                label: l10n.editorDoneSemanticLabel,
                child: ExcludeSemantics(
                  child: DayzButton(
                    size: DayzButtonSize.small,
                    onPressed: _handleDone,
                    child: Text(l10n.editorDone),
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            DayzSpacing.s4,
            DayzSpacing.s4,
            DayzSpacing.s4,
            0,
          ),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  DayzIcon.path(
                    DayzIcons.calendarPath,
                    size: 12,
                    color: colors.accentInk,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _dateKicker(context),
                    style: context.dayzText.overline.copyWith(
                      color: colors.accentInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DayzSpacing.s2),
              _TitleField(controller: _titleController),
              const SizedBox(height: DayzSpacing.s3),
              const EditorMetaBar(),
              const SizedBox(height: DayzSpacing.s5),
            ],
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DayzSpacing.s4,
              0,
              DayzSpacing.s4,
              DayzSpacing.s16,
            ),
            child: _EditorBody(
              mode: widget.mode,
              bodyPreview: widget.bodyPreview,
              editorState: _editorState,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.bg,
      body: DayzEditorMobileToolbar(
        editorState: _editorState,
        toolbarItems: buildDayzToolbarItems(
          context: context,
          l10n: l10n,
          onImageTap: () {
            EditorImageInserter.pickAndInsert(
              context: context,
              editorState: _editorState,
              mediaStore: widget.mediaStore,
              entryId: widget.entryId,
              pickImageOp: widget.pickImageOp,
            );
          },
        ),
        child: mainContent,
      ),
    );
  }

  Future<void> _handleClose() async {
    final coord = widget.draftCoordinator;
    if (coord != null) {
      await coord.forceFlush();
    }
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      if (mounted) {
        Navigator.maybePop(context);
      }
    }
  }

  Future<void> _handleDone() async {
    final coord = widget.draftCoordinator;
    if (coord != null) {
      await coord.forceFlush();
    }
    final repo = widget.entryRepo;
    final entryId = widget.entryId;
    if (repo != null) {
      final contentJson = EditorDocCodec.encode(_editorState.document);
      final rawPlain = EditorDocCodec.extractPlainText(_editorState.document);
      final title = _titleController.text;
      final contentPlain = '$title\n$rawPlain';

      bool hasSave = false;
      try {
        await repo.save(
          id: entryId ?? '',
          contentJson: contentJson,
          contentPlain: contentPlain,
        );
        hasSave = true;
      } on NoSuchMethodError {
        hasSave = false;
      }

      if (!hasSave) {
        if (widget.mode == EditorScreenMode.empty || entryId == null) {
          String localTz = 'Asia/Shanghai';
          try {
            localTz = tz.local.name;
            if (localTz == 'UTC') {
              localTz = 'Etc/UTC';
            }
          } catch (_) {}

          await repo.create(
            contentJson: contentJson,
            contentPlain: contentPlain,
            entryDtUtc: widget.entryDate.toUtc(),
            entryTz: localTz,
          );
        } else {
          await repo.update(
            entryId,
            contentJson: contentJson,
            contentPlain: contentPlain,
          );
        }
      }
    }
    if (widget.onDone != null) {
      widget.onDone!();
    } else {
      if (mounted) {
        Navigator.maybePop(context);
      }
    }
  }

  String _navTitle(AppLocalizations l10n) {
    return (widget.mode == EditorScreenMode.empty && !_hasDraftSaved)
        ? l10n.editorTitleNew
        : l10n.editorTitleDraftSaved;
  }

  String _dateKicker(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = DateUtils.isSameDay(widget.entryDate, DateTime.now());
    final date = DateFormat.MMMMd(locale).format(widget.entryDate);
    final weekday = DateFormat.E(locale).format(widget.entryDate);
    if (today) {
      return AppLocalizations.of(context).editorDateKickerToday(date, weekday);
    }
    return AppLocalizations.of(context).editorDateKicker(date, weekday);
  }

  static EditorState _createEditorState(EditorScreen widget) {
    final initialContentJson = widget.initialContentJson;
    if (initialContentJson != null && initialContentJson.isNotEmpty) {
      try {
        final decoded = EditorDocCodec.decode(initialContentJson);
        return EditorState(document: decoded.document);
      } catch (_) {
        // Fallback
      }
    }
    final bodyPreview = widget.bodyPreview;
    if (bodyPreview == null || bodyPreview.isEmpty) {
      // Seed an empty paragraph (withInitialText:true) so a brand-new entry
      // has a tappable/editable block. Without it the root page has zero
      // children, the editor's tap handler can't resolve a node, and the
      // cursor/IME can never attach — the body becomes inert.
      return EditorState.blank(withInitialText: true);
    }
    return EditorState(
      document: Document(
        root: pageNode(children: [paragraphNode(text: bodyPreview)]),
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final l10n = AppLocalizations.of(context);

    return TextField(
      key: EditorScreen.titleFieldKey,
      controller: controller,
      cursorColor: colors.accent,
      style: text.h1.copyWith(color: colors.ink),
      decoration:
          InputDecoration.collapsed(
            hintText: l10n.editorTitlePlaceholder,
            hintStyle: text.h1.copyWith(color: colors.ink4),
            border: InputBorder.none,
          ).copyWith(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
    );
  }
}

class _EditorBody extends StatefulWidget {
  const _EditorBody({
    required this.mode,
    required this.editorState,
    this.bodyPreview,
  });

  final EditorScreenMode mode;
  final EditorState editorState;
  final String? bodyPreview;

  @override
  State<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends State<_EditorBody> {
  bool _isEmpty = true;
  StreamSubscription? _subscription;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _isEmpty = _checkIsEmpty();
    _subscription = widget.editorState.transactionStream.listen(
      (_) => _handleDocChanged(),
    );
  }

  @override
  void didUpdateWidget(_EditorBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorState != widget.editorState) {
      _subscription?.cancel();
      _subscription = widget.editorState.transactionStream.listen(
        (_) => _handleDocChanged(),
      );
      _isEmpty = _checkIsEmpty();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDocChanged() {
    final curEmpty = _checkIsEmpty();
    if (_isEmpty != curEmpty) {
      setState(() {
        _isEmpty = curEmpty;
      });
    }
  }

  bool _checkIsEmpty() {
    final text = EditorDocCodec.extractPlainText(
      widget.editorState.document,
    ).trim();
    return text.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final l10n = AppLocalizations.of(context);
    final content =
        widget.bodyPreview ??
        (widget.mode == EditorScreenMode.empty
            ? l10n.editorBodyPlaceholderEmpty
            : l10n.editorBodyPlaceholderWriting);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        if (widget.editorState.selection != null) return;
        final editorState = widget.editorState;
        final root = editorState.document.root;
        Path targetPath;
        int offset;
        if (root.children.isEmpty) {
          // Defensive: a document with no editable block cannot host a
          // cursor. Seed an empty paragraph before placing the caret so
          // focus/IME can attach even if the doc lost all of its nodes.
          final transaction = editorState.transaction
            ..insertNode([0], paragraphNode());
          await editorState.apply(transaction);
          targetPath = [0];
          offset = 0;
        } else {
          final lastNode = root.children.last;
          targetPath = lastNode.path;
          offset = lastNode.delta?.length ?? 0;
        }
        // Use the uiEvent reason so the keyboard service attaches the IME
        // and requests focus through AppFlowy's normal selection flow.
        await editorState.updateSelectionWithReason(
          Selection.collapsed(Position(path: targetPath, offset: offset)),
          reason: SelectionUpdateReason.uiEvent,
        );
      },
      child: Stack(
        children: [
          const Positioned.fill(child: SizedBox()),
          AppFlowyEditor(
            editorState: widget.editorState,
            focusNode: _focusNode,
            shrinkWrap: true,
            blockComponentBuilders: EditorBlockRegistry.editableBuilders(),
            editorStyle: dayzEditorStyle(context),
          ),
          if (_isEmpty)
            Positioned(
              key: EditorScreen.bodyPlaceholderKey,
              left: 0,
              top: 0,
              right: 0,
              child: IgnorePointer(
                child: Text(
                  content,
                  style: text.diary.copyWith(color: colors.ink3),
                ),
              ),
            )
          else
            Positioned(
              key: EditorScreen.bodyPlaceholderKey,
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: Text(
                  content,
                  style: text.diary.copyWith(color: Colors.transparent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
