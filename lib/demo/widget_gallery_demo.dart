// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../ui/components.dart';
import '../ui/theme/dayz_colors.dart';
import '../ui/theme/dayz_text_theme.dart';
import '../ui/theme/dayz_theme.dart';
import '../ui/theme/dayz_tokens.g.dart';

class GalleryTheme {
  final String name;
  final ThemeData data;
  const GalleryTheme({required this.name, required this.data});
}

final List<GalleryTheme> widgetGalleryThemes = [
  GalleryTheme(name: 'purpleLight', data: DayzThemes.purpleLight),
  GalleryTheme(name: 'purpleDark', data: DayzThemes.purpleDark),
  GalleryTheme(name: 'amberLight', data: DayzThemes.amberLight),
  GalleryTheme(name: 'amberDark', data: DayzThemes.amberDark),
  GalleryTheme(name: 'sageLight', data: DayzThemes.sageLight),
  GalleryTheme(name: 'sageDark', data: DayzThemes.sageDark),
];

/// Direct visual gallery for DayZ UI kit components.
///
/// Author: @Ray
class WidgetGalleryDemo extends StatefulWidget {
  const WidgetGalleryDemo({super.key});

  @override
  State<WidgetGalleryDemo> createState() => _WidgetGalleryDemoState();
}

class _WidgetGalleryDemoState extends State<WidgetGalleryDemo> {
  int _themeIndex = 0;
  int _sectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedTheme = widgetGalleryThemes[_themeIndex];

    return Theme(
      data: selectedTheme.data,
      child: Builder(
        builder: (context) {
          final colors = context.dayz;
          final text = context.dayzText;
          final selectedSection = _gallerySections[_sectionIndex];

          return Scaffold(
            backgroundColor: colors.bg,
            body: SafeArea(
              child: Column(
                children: [
                  _GalleryHeader(
                    themeIndex: _themeIndex,
                    sectionIndex: _sectionIndex,
                    onThemeChanged: (index) {
                      setState(() {
                        _themeIndex = index;
                      });
                    },
                    onSectionChanged: (index) {
                      setState(() {
                        _sectionIndex = index;
                      });
                    },
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        DayzSpacing.s4,
                        DayzSpacing.s2,
                        DayzSpacing.s4,
                        DayzSpacing.s6,
                      ),
                      children: [
                        _ThemeStrip(
                          themeIndex: _themeIndex,
                          onThemeChanged: (index) {
                            setState(() {
                              _themeIndex = index;
                            });
                          },
                        ),
                        const SizedBox(height: DayzSpacing.s4),
                        Text(
                          selectedSection.title,
                          style: text.h2.copyWith(
                            fontSize: 22,
                            height: 1.25,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: DayzSpacing.s1),
                        Text(
                          selectedSection.note,
                          style: text.caption.copyWith(
                            fontSize: 13,
                            color: colors.ink3,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: DayzSpacing.s4),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 720;
                            return _GalleryPreviewGrid(
                              columns: wide ? 2 : 1,
                              previews: selectedSection.previews,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widgetbook-backed matrix kept for exhaustive state/theme inspection.
///
/// Author: @Ray

class _GallerySection {
  const _GallerySection({
    required this.title,
    required this.note,
    required this.previews,
  });

  final String title;
  final String note;
  final List<_GalleryPreview> previews;
}

class _GalleryPreview {
  const _GalleryPreview({
    required this.title,
    required this.source,
    required this.child,
    this.height,
    this.fullBleed = false,
  });

  final String title;
  final String source;
  final Widget child;
  final double? height;
  final bool fullBleed;
}

final List<_GallerySection> _gallerySections = [
  _GallerySection(
    title: '基础控件',
    note:
        'DESIGN-REF §3: .btn / .field / .switch / .opt / .segmented / .tag / .mood / .weather-chip / .toolbar',
    previews: [
      _GalleryPreview(
        title: '按钮',
        source:
            'docs/DESIGN-REF.md:117 · design-system/assets/spec.css:252 · design-system.html:290',
        child: _buttonVariants(compact: true),
      ),
      _GalleryPreview(
        title: '输入',
        source:
            'docs/DESIGN-REF.md:124 · design-system/assets/spec.css:275 · timeline.html:28 · screen.js:231',
        child: _textFields(compact: true),
      ),
      _GalleryPreview(
        title: '选择控件',
        source:
            'docs/DESIGN-REF.md:135/140/147 · design-system/assets/spec.css:292/307/321',
        child: _choiceControls(compact: true),
      ),
      _GalleryPreview(
        title: '标签与状态',
        source:
            'docs/DESIGN-REF.md:155/162 · design-system/assets/spec.css:335/344/360',
        child: _chips(compact: true),
      ),
      _GalleryPreview(
        title: '编辑器工具栏',
        source: 'docs/DESIGN-REF.md:171 · design-system/assets/spec.css:457',
        child: _toolbar(compact: true),
      ),
      _GalleryPreview(
        title: '弹窗',
        source:
            'docs/DESIGN-REF.md:174/185 · design-system/assets/spec.css:527 · design-system.html:393',
        child: _dialog(compact: true),
      ),
    ],
  ),
  _GallerySection(
    title: '内容组件',
    note: 'DESIGN-REF §3: .entry / .gallery / 收藏星规范路径',
    previews: [
      _GalleryPreview(
        title: '日记卡片',
        source:
            'docs/DESIGN-REF.md:211 · design-system/assets/spec.css:393 · timeline.html:40',
        child: _entryCard(compact: true),
        height: 330,
      ),
      _GalleryPreview(
        title: '相册九宫格',
        source:
            'docs/DESIGN-REF.md:230 · design-system/assets/spec.css:422 · timeline.html:46/78',
        child: _galleryCard(compact: true),
      ),
      _GalleryPreview(
        title: '收藏星',
        source:
            'docs/DESIGN-REF.md:362 · pages/assets/screen.js:162 · timeline.html:136',
        child: _favoriteStage(),
      ),
    ],
  ),
  _GallerySection(
    title: '页面复用件',
    note:
        'DESIGN-REF §3b/§3c: .tl-month / .year-sep / .search-head / .set-* / .empty',
    previews: [
      _GalleryPreview(
        title: '时间线头与年份分隔',
        source:
            'docs/DESIGN-REF.md:247/259 · design-system/assets/spec.css:786/820 · timeline.html:38',
        child: _timelineStage(),
      ),
      _GalleryPreview(
        title: '搜索与设置行',
        source:
            'docs/DESIGN-REF.md:264/270 · design-system/assets/spec.css:826/874 · pages/assets/screen.css:184',
        child: _settings(compact: true),
        height: 270,
      ),
      _GalleryPreview(
        title: '空状态',
        source:
            'docs/DESIGN-REF.md:292 · pages/assets/screen.css:127 · timeline.html:113',
        child: _emptyStage(),
        height: 250,
      ),
    ],
  ),
  _GallerySection(
    title: '跨屏外壳',
    note: 'DESIGN-REF §3/§4: toast / sheet / .app-top 玻璃顶栏 / .fab-wrap',
    previews: [
      _GalleryPreview(
        title: '毛玻璃顶栏',
        source:
            'docs/DESIGN-REF.md:278 · pages/assets/screen.css:48/57 · timeline.html:18',
        child: _glassAppBar(compact: true),
        height: 240,
        fullBleed: true,
      ),
      _GalleryPreview(
        title: 'Toast',
        source:
            'docs/DESIGN-REF.md:174 · design-system/assets/spec.css:492 · design-system.html:379',
        child: _toastStage(compact: true),
      ),
      _GalleryPreview(
        title: 'Sheet',
        source:
            'docs/DESIGN-REF.md:187 · design-system/assets/spec.css:540 · pages/assets/screen.js:173',
        child: _sheetStage(compact: true),
      ),
      _GalleryPreview(
        title: 'FAB 速拨',
        source:
            'docs/DESIGN-REF.md:336 · design-system/assets/spec.css:709 · pages/assets/screen.js:113',
        child: _fabStage(compact: true),
        height: 320,
        fullBleed: true,
      ),
    ],
  ),
];

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.themeIndex,
    required this.sectionIndex,
    required this.onThemeChanged,
    required this.onSectionChanged,
  });

  final int themeIndex;
  final int sectionIndex;
  final ValueChanged<int> onThemeChanged;
  final ValueChanged<int> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(bottom: BorderSide(color: colors.hairline)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DayzSpacing.s4,
          DayzSpacing.s3,
          DayzSpacing.s4,
          DayzSpacing.s3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'UI Kit 组件画廊',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.h2.copyWith(
                      fontSize: 23,
                      height: 1.2,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DayzSpacing.s3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _gallerySections.length; i++) ...[
                    if (i > 0) const SizedBox(width: DayzSpacing.s2),
                    _SectionPill(
                      label: _gallerySections[i].title,
                      selected: i == sectionIndex,
                      onTap: () => onSectionChanged(i),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  const _SectionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;

    return Material(
      color: selected ? colors.accent : colors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? colors.accent : colors.hairline),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DayzSpacing.s4),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.body.copyWith(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? colors.onAccent : colors.ink2,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeStrip extends StatelessWidget {
  const _ThemeStrip({required this.themeIndex, required this.onThemeChanged});

  final int themeIndex;
  final ValueChanged<int> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(DayzRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DayzSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '主题',
              style: text.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.ink3,
                height: 1,
              ),
            ),
            const SizedBox(height: DayzSpacing.s3),
            Wrap(
              spacing: DayzSpacing.s2,
              runSpacing: DayzSpacing.s2,
              children: [
                for (var i = 0; i < widgetGalleryThemes.length; i++)
                  _ThemeSwatchButton(
                    theme: widgetGalleryThemes[i],
                    selected: i == themeIndex,
                    onTap: () => onThemeChanged(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwatchButton extends StatelessWidget {
  const _ThemeSwatchButton({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final GalleryTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentColors = context.dayz;
    final swatchColors =
        theme.data.extension<DayzColors>() ?? DayzColors.purpleLight;
    final text = context.dayzText;
    final brightness = theme.data.brightness == Brightness.dark ? '暗' : '亮';

    return Material(
      color: selected ? currentColors.accentSoft : currentColors.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DayzRadii.full),
        side: BorderSide(
          color: selected ? currentColors.accent : currentColors.hairline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DayzRadii.full),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ThemeDot(colors: swatchColors),
                const SizedBox(width: DayzSpacing.s2),
                Text(
                  '${_themeFamilyLabel(theme.name)} $brightness',
                  style: text.body.copyWith(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: currentColors.ink2,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({required this.colors});

  final DayzColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.bg,
        border: Border.all(color: colors.hairline2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniColor(color: colors.accent),
            _MiniColor(color: colors.accentSoft2),
            _MiniColor(color: colors.favorite),
          ],
        ),
      ),
    );
  }
}

class _MiniColor extends StatelessWidget {
  const _MiniColor({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 9,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _GalleryPreviewGrid extends StatelessWidget {
  const _GalleryPreviewGrid({required this.columns, required this.previews});

  final int columns;
  final List<_GalleryPreview> previews;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < previews.length; i++) ...[
            if (i > 0) const SizedBox(height: DayzSpacing.s4),
            _PreviewPanel(preview: previews[i]),
          ],
        ],
      );
    }

    return Wrap(
      spacing: DayzSpacing.s4,
      runSpacing: DayzSpacing.s4,
      children: [
        for (final preview in previews)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - DayzSpacing.s4 * 3) / 2,
            child: _PreviewPanel(preview: preview),
          ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.preview});

  final _GalleryPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.dayz;
    final text = context.dayzText;

    final framedChild = preview.fullBleed
        ? preview.child
        : Padding(
            padding: const EdgeInsets.all(DayzSpacing.s4),
            child: Align(alignment: Alignment.topLeft, child: preview.child),
          );
    final content = preview.height == null
        ? framedChild
        : SizedBox(
            height: preview.height,
            child: ClipRect(
              child: preview.fullBleed
                  ? framedChild
                  : SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: framedChild,
                    ),
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(DayzRadii.md),
        boxShadow: colors.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DayzRadii.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DayzSpacing.s4,
                DayzSpacing.s3,
                DayzSpacing.s4,
                DayzSpacing.s3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '真源：${preview.source}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.caption.copyWith(
                      fontSize: 11.5,
                      color: colors.ink3,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.hairline),
            content,
          ],
        ),
      ),
    );
  }
}

String _themeFamilyLabel(String name) {
  if (name.startsWith('purple')) {
    return '雾紫';
  }
  if (name.startsWith('amber')) {
    return '暖黄';
  }
  return '雾绿';
}

final Widget _matrixHome = Builder(
  builder: (context) {
    final colors = context.dayz;
    final text = context.dayzText;
    return Scaffold(
      backgroundColor: colors.bg,
      body: Center(
        child: Text(
          'DayZ UI Kit Matrix',
          style: text.h2.copyWith(color: colors.ink),
        ),
      ),
    );
  },
);

Widget _stage(Widget child) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(DayzSpacing.s5),
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

Widget _buttonVariants({bool compact = false}) {
  final content = Wrap(
    spacing: DayzSpacing.s3,
    runSpacing: DayzSpacing.s3,
    children: const [
      DayzButton(onPressed: _noop, child: Text('写一篇')),
      DayzButton(
        variant: DayzButtonVariant.soft,
        onPressed: _noop,
        child: Text('恢复'),
      ),
      DayzButton(
        variant: DayzButtonVariant.ghost,
        onPressed: _noop,
        child: Text('筛选'),
      ),
      DayzButton(
        variant: DayzButtonVariant.text,
        onPressed: _noop,
        child: Text('查看全部'),
      ),
      DayzButton(
        variant: DayzButtonVariant.danger,
        onPressed: _noop,
        child: Text('彻底删除'),
      ),
      DayzButton(onPressed: null, child: Text('不可用')),
    ],
  );

  return compact ? content : _stage(content);
}

Widget _buttonIcon() {
  return _stage(
    DayzButton.icon(
      icon: const Icon(Icons.more_horiz),
      semanticLabel: AppStrings.more,
      onPressed: _noop,
    ),
  );
}

Widget _textFields({bool compact = false}) {
  final content = const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DayzTextField(label: '标题', hintText: '今天发生了什么'),
      SizedBox(height: DayzSpacing.s4),
      DayzTextField.textarea(label: '正文', hintText: '写下细节、心情和地点'),
    ],
  );

  return compact ? content : _stage(content);
}

Widget _choiceControls({bool compact = false}) {
  const content = _ChoiceControlsPreview();
  return compact ? content : _stage(content);
}

class _ChoiceControlsPreview extends StatefulWidget {
  const _ChoiceControlsPreview();

  @override
  State<_ChoiceControlsPreview> createState() => _ChoiceControlsPreviewState();
}

class _ChoiceControlsPreviewState extends State<_ChoiceControlsPreview> {
  bool _switchValue = true;
  bool _checkboxValue = true;
  bool _radioValue = false;
  String _segmentValue = 'timeline';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DayzSwitch(
          value: _switchValue,
          semanticLabel: '本地备份',
          onChanged: (value) {
            setState(() {
              _switchValue = value;
            });
          },
        ),
        const SizedBox(height: DayzSpacing.s4),
        DayzOption.checkbox(
          selected: _checkboxValue,
          semanticLabel: '同步到本地备份',
          onTap: () {
            setState(() {
              _checkboxValue = !_checkboxValue;
            });
          },
          child: const Text('同步到本地备份'),
        ),
        const SizedBox(height: DayzSpacing.s3),
        DayzOption.radio(
          selected: _radioValue,
          semanticLabel: '跟随系统外观',
          onTap: () {
            setState(() {
              _radioValue = !_radioValue;
            });
          },
          child: const Text('跟随系统外观'),
        ),
        const SizedBox(height: DayzSpacing.s4),
        DayzSegmented<String>(
          value: _segmentValue,
          onChanged: (value) {
            setState(() {
              _segmentValue = value;
            });
          },
          segments: const [
            DayzSegment(value: 'timeline', child: Text('时间线')),
            DayzSegment(value: 'calendar', child: Text('日历')),
          ],
        ),
      ],
    );
  }
}

Widget _chips({bool compact = false}) {
  final content = Wrap(
    spacing: DayzSpacing.s3,
    runSpacing: DayzSpacing.s3,
    children: [
      DayzTag(onRemove: _noop, child: const Text('# 生活')),
      const DayzTag(variant: DayzTagVariant.outline, child: Text('# 工作')),
      DayzMoodChip(label: '愉快', selected: true, onTap: _noop),
      DayzMoodChip(label: '平静', face: DayzMoodFace.calm, onTap: _noop),
      DayzWeatherChip(label: '晴 26°', onTap: _noop),
      DayzWeatherChip(label: '雨', glyph: DayzWeatherGlyph.rain, onTap: _noop),
    ],
  );

  return compact ? content : _stage(content);
}

Widget _toolbar({bool compact = false}) {
  final content = DayzToolbar(
    items: [
      DayzToolbarItem.button(
        semanticLabel: '加粗',
        label: 'B',
        active: true,
        onPressed: _noop,
      ),
      const DayzToolbarItem.divider(),
      DayzToolbarItem.button(semanticLabel: '斜体', label: 'I', onPressed: _noop),
      DayzToolbarItem.button(
        semanticLabel: '列表',
        icon: const Icon(Icons.format_list_bulleted_rounded),
        onPressed: _noop,
      ),
      DayzToolbarItem.button(
        semanticLabel: '图片',
        icon: const Icon(Icons.image_outlined),
        onPressed: _noop,
      ),
    ],
  );

  return compact ? content : _stage(content);
}

Widget _entryCard({bool compact = false}) {
  final content = SizedBox(
    width: 360,
    child: DayzEntryCard(
      title: '五月雨后',
      summary: '傍晚的风很轻，楼下桂花树被雨水洗过，香气比早上更清楚。',
      date: DateTime(2026, 5, 29),
      tags: const ['# 生活'],
      meta: const [DayzEntryMeta(label: '上海', icon: Icon(Icons.place))],
      favorite: true,
      cover: _images(1).first,
    ),
  );

  return compact ? content : _stage(content);
}

Widget _galleryCard({bool compact = false}) {
  final content = LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 320.0;
      return SizedBox(
        width: width.clamp(260.0, 360.0),
        child: DayzGallery(images: _images(10), onMoreTap: _noop),
      );
    },
  );

  return compact ? content : _stage(content);
}

Widget _pageComponents() {
  return _stage(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DayzMonthHeader(month: DateTime(2026, 5), entryCount: 12),
        DayzYearSeparator(year: 2024, referenceDate: DateTime(2026, 5, 30)),
        const SizedBox(height: DayzSpacing.s6),
        const DayzEmptyState(),
      ],
    ),
  );
}

Widget _settings({bool compact = false}) {
  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: const [
      DayzSearchField(),
      SizedBox(height: DayzSpacing.s4),
      DayzSetGroup(
        label: '偏好',
        children: [
          DayzSetRow(
            icon: Icon(Icons.palette_outlined),
            title: '主题',
            subtitle: '影响全部本地界面',
            value: '雾紫',
            showChevron: true,
          ),
          DayzSetRow(
            icon: Icon(Icons.lock_outline),
            title: '本地加密',
            subtitle: '仅保存在这台设备',
            trailing: DayzSwitch(value: true),
          ),
        ],
      ),
    ],
  );

  return compact ? content : _stage(content);
}

Widget _glassAppBar({bool compact = false}) {
  final content = Scaffold(
    backgroundColor: Colors.transparent,
    body: CustomScrollView(
      slivers: const [
        DayzGlassAppBar(scrolledUnder: true, title: Text('时间线')),
        SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    ),
  );

  return content;
}

Widget _toastStage({bool compact = false}) {
  final content = Builder(
    builder: (context) {
      return Wrap(
        spacing: DayzSpacing.s3,
        runSpacing: DayzSpacing.s3,
        children: [
          DayzButton(
            variant: DayzButtonVariant.soft,
            onPressed: () => DayzToast.show(
              context,
              AppStrings.toastDefault,
              DayzToastTone.info,
            ),
            child: const Text(AppStrings.toastDefault),
          ),
          DayzButton(
            variant: DayzButtonVariant.danger,
            onPressed: () => DayzToast.show(
              context,
              AppStrings.delete,
              DayzToastTone.danger,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      );
    },
  );

  return compact ? content : _stage(content);
}

Widget _sheetStage({bool compact = false}) {
  final content = Builder(
    builder: (context) {
      return Wrap(
        spacing: DayzSpacing.s3,
        runSpacing: DayzSpacing.s3,
        children: [
          DayzButton(
            onPressed: () => DayzSheet.actions<void>(
              context,
              items: [
                DayzSheetItem(
                  label: AppStrings.edit,
                  icon: Icons.edit_outlined,
                  onTap: _noop,
                ),
              ],
            ),
            child: const Text('动作菜单'),
          ),
          DayzButton(
            variant: DayzButtonVariant.danger,
            onPressed: () => DayzSheet.confirm(
              context,
              title: AppStrings.delete,
              desc: AppStrings.emptyDescription,
            ),
            child: const Text(AppStrings.confirm),
          ),
        ],
      );
    },
  );

  return compact ? content : _stage(content);
}

Widget _fabStage({bool compact = false}) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: DayzFab(
      onTap: _noop,
      actions: [
        DayzFabAction(
          label: AppStrings.camera,
          icon: const Icon(Icons.photo_camera_outlined),
          onTap: _noop,
        ),
        DayzFabAction(
          label: AppStrings.voice,
          icon: const Icon(Icons.mic_none_outlined),
          onTap: _noop,
        ),
      ],
    ),
  );
}

Widget _dialog({bool compact = false}) {
  final content = DayzDialog(
    title: const Text(AppStrings.delete),
    message: const Text(AppStrings.emptyDescription),
    actions: [
      DayzButton(
        variant: DayzButtonVariant.ghost,
        onPressed: _noop,
        child: const Text(AppStrings.cancel),
      ),
      DayzButton(
        variant: DayzButtonVariant.danger,
        onPressed: _noop,
        child: const Text(AppStrings.delete),
      ),
    ],
  );

  return compact ? content : _stage(content);
}

Widget _favoriteStage() {
  return const Wrap(
    spacing: DayzSpacing.s4,
    runSpacing: DayzSpacing.s3,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      DayzFavoriteStar(isFavorite: false, size: 28),
      DayzFavoriteStar(isFavorite: true, size: 28),
    ],
  );
}

Widget _timelineStage() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      DayzMonthHeader(month: DateTime(2026, 5), entryCount: 12),
      const SizedBox(height: DayzSpacing.s3),
      DayzYearSeparator(year: 2024, referenceDate: DateTime(2026, 5, 30)),
    ],
  );
}

Widget _emptyStage() {
  return const Center(child: DayzEmptyState());
}

List<ImageProvider> _images(int count) {
  return List<ImageProvider>.generate(
    count,
    (_) => MemoryImage(_transparentPng),
  );
}

void _noop() {}

final Uint8List _transparentPng = Uint8List.fromList(const [
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
]);
