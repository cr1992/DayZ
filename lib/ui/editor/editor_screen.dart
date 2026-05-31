// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dayz/editor/contract/editor_block_registry.dart';
import 'package:dayz/l10n/gen/app_localizations.dart';
import 'package:dayz/ui/shell/dayz_glass_app_bar.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/widgets/dayz_button.dart';

import 'editor_meta_bar.dart';
import 'editor_style.dart';

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
  });

  const EditorScreen.empty({
    Key? key,
    required DateTime entryDate,
    VoidCallback? onClose,
    VoidCallback? onDone,
  }) : this(
         key: key,
         mode: EditorScreenMode.empty,
         entryDate: entryDate,
         onClose: onClose,
         onDone: onDone,
       );

  const EditorScreen.writing({
    Key? key,
    required DateTime entryDate,
    String? title,
    String? bodyPreview,
    VoidCallback? onClose,
    VoidCallback? onDone,
  }) : this(
         key: key,
         mode: EditorScreenMode.writing,
         entryDate: entryDate,
         title: title,
         bodyPreview: bodyPreview,
         onClose: onClose,
         onDone: onDone,
       );

  const EditorScreen.rich({
    Key? key,
    required DateTime entryDate,
    String? title,
    String? bodyPreview,
    VoidCallback? onClose,
    VoidCallback? onDone,
  }) : this(
         key: key,
         mode: EditorScreenMode.rich,
         entryDate: entryDate,
         title: title,
         bodyPreview: bodyPreview,
         onClose: onClose,
         onDone: onDone,
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

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _titleController;
  late EditorState _editorState;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _editorState = _createEditorState(widget);
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title &&
        _titleController.text != (widget.title ?? '')) {
      _titleController.text = widget.title ?? '';
    }
    if (oldWidget.mode != widget.mode ||
        oldWidget.bodyPreview != widget.bodyPreview) {
      final previous = _editorState;
      _editorState = _createEditorState(widget);
      previous.dispose();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.dayz;

    return ColoredBox(
      color: colors.bg,
      child: CustomScrollView(
        slivers: [
          DayzGlassAppBar(
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: DayzSpacing.s2),
              child: DayzButton.icon(
                key: EditorScreen.closeButtonKey,
                icon: const Icon(Icons.close),
                semanticLabel: l10n.editorCloseSemanticLabel,
                variant: DayzButtonVariant.ghost,
                onPressed: widget.onClose ?? () => Navigator.maybePop(context),
              ),
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
                      onPressed:
                          widget.onDone ?? () => Navigator.maybePop(context),
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
              DayzSpacing.s16,
            ),
            sliver: SliverList.list(
              children: [
                Text(_dateKicker(context), style: context.dayzText.overline),
                const SizedBox(height: DayzSpacing.s2),
                _TitleField(controller: _titleController),
                const SizedBox(height: DayzSpacing.s3),
                const EditorMetaBar(),
                const SizedBox(height: DayzSpacing.s5),
                _EditorBody(
                  mode: widget.mode,
                  bodyPreview: widget.bodyPreview,
                  editorState: _editorState,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _navTitle(AppLocalizations l10n) {
    return widget.mode == EditorScreenMode.empty
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
    final bodyPreview = widget.bodyPreview;
    if (bodyPreview == null || bodyPreview.isEmpty) {
      return EditorState.blank(withInitialText: false);
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

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.mode,
    required this.editorState,
    this.bodyPreview,
  });

  final EditorScreenMode mode;
  final EditorState editorState;
  final String? bodyPreview;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;
    final l10n = AppLocalizations.of(context);
    final content =
        bodyPreview ??
        (mode == EditorScreenMode.empty
            ? l10n.editorBodyPlaceholderEmpty
            : l10n.editorBodyPlaceholderWriting);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(DayzRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DayzSpacing.s4),
        child: Stack(
          children: [
            SizedBox(
              height: bodyPreview == null || bodyPreview!.isEmpty ? 132 : 180,
              child: AppFlowyEditor(
                editorState: editorState,
                shrinkWrap: true,
                blockComponentBuilders: EditorBlockRegistry.editableBuilders(),
                editorStyle: dayzEditorStyle(context),
              ),
            ),
            if (bodyPreview == null || bodyPreview!.isEmpty)
              Positioned.fill(
                key: EditorScreen.bodyPlaceholderKey,
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
                    style: text.diary.copyWith(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
