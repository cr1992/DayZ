// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:dayz/ui/editor/editor_screen.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';
import 'package:dayz/ui/theme/dayz_colors.dart';
import 'package:dayz/ui/theme/dayz_tokens.g.dart';
import 'package:dayz/ui/theme/dayz_text_theme.dart';

/// EditorScreen 交互式演示 Demo。
///
/// Author: @Ray
class EditorScreenDemo extends StatefulWidget {
  const EditorScreenDemo({super.key});

  @override
  State<EditorScreenDemo> createState() => _EditorScreenDemoState();
}

class _EditorScreenDemoState extends State<EditorScreenDemo> {
  String _currentThemeKey = 'purpleLight';
  String _currentState = 'empty'; // 'empty', 'writing', 'rich'

  final _draftCoordinator = _DemoDraftCoordinator();
  final _entryRepo = _DemoEntryRepo();
  final _mediaStore = _DemoMediaStore();

  @override
  Widget build(BuildContext context) {
    final themeData = DayzThemes.all[_currentThemeKey]!;
    final colors = themeData.extension<DayzColors>()!;
    final typography = themeData.extension<DayzTextTheme>()!;

    return Theme(
      data: themeData,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Controller bar for switching states and themes
              Container(
                color: colors.surface2,
                padding: const EdgeInsets.all(DayzSpacing.s2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('状态: ', style: typography.caption.copyWith(color: colors.ink2)),
                        const SizedBox(width: DayzSpacing.s2),
                        Wrap(
                          spacing: DayzSpacing.s1,
                          children: ['empty', 'writing', 'rich'].map((state) {
                            final isSelected = _currentState == state;
                            return ChoiceChip(
                              label: Text(state),
                              selected: isSelected,
                              selectedColor: colors.accentSoft2,
                              backgroundColor: colors.surface,
                              labelStyle: typography.caption.copyWith(
                                color: isSelected ? colors.accentStrong : colors.ink2,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _currentState = state;
                                  });
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: DayzSpacing.s1),
                    Row(
                      children: [
                        Text('主题: ', style: typography.caption.copyWith(color: colors.ink2)),
                        const SizedBox(width: DayzSpacing.s2),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: DayzThemes.all.keys.map((key) {
                                final isSelected = _currentThemeKey == key;
                                final itemTheme = DayzThemes.all[key]!;
                                final itemColors = itemTheme.extension<DayzColors>()!;
                                return Padding(
                                  padding: const EdgeInsets.only(right: DayzSpacing.s1),
                                  child: ChoiceChip(
                                    label: Text(key),
                                    selected: isSelected,
                                    selectedColor: itemColors.accentSoft2,
                                    backgroundColor: colors.surface,
                                    labelStyle: typography.caption.copyWith(
                                      color: isSelected ? itemColors.accentStrong : colors.ink2,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _currentThemeKey = key;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // The Editor Screen
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey('$_currentState-$_currentThemeKey'),
                  child: _buildEditor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final now = DateTime.now();
    return switch (_currentState) {
      'empty' => EditorScreen.empty(
          entryDate: now,
          entryId: 'demo-entry-empty',
          draftCoordinator: _draftCoordinator,
          entryRepo: _entryRepo,
          mediaStore: _mediaStore,
        ),
      'writing' => EditorScreen.writing(
          entryDate: now,
          entryId: 'demo-entry-writing',
          title: '写一段话',
          bodyPreview: '我正在使用 DayZ 记录今天的日常。今天的天气很不错。',
          draftCoordinator: _draftCoordinator,
          entryRepo: _entryRepo,
          mediaStore: _mediaStore,
        ),
      'rich' => EditorScreen.rich(
          entryDate: now,
          entryId: 'demo-entry-rich',
          title: '精致排版',
          bodyPreview: '这是一篇带有多彩排版的日记草稿。有引用块、代办项以及插图等等。',
          draftCoordinator: _draftCoordinator,
          entryRepo: _entryRepo,
          mediaStore: _mediaStore,
        ),
      _ => const Placeholder(),
    };
  }
}

class _DemoDraftCoordinator {
  // Signature MUST match EditorDraftBridge's named-arg call (and the real
  // DraftCoordinator / FakeDraftCoordinator); otherwise editing in the demo
  // throws NoSuchMethodError on the first transaction/selection change.
  void onChanged({
    required String? targetId,
    required String draftJson,
    required bool isNew,
    int? cursorPos,
  }) {
    debugPrint(
      '[_DemoDraftCoordinator] onChanged targetId=$targetId isNew=$isNew '
      'cursorPos=$cursorPos',
    );
  }

  Future<void> forceFlush() async {
    debugPrint('[_DemoDraftCoordinator] forceFlush completed');
  }
}

class _DemoEntryRepo {
  Future<void> save({
    required String id,
    required String contentJson,
    required String contentPlain,
  }) async {
    debugPrint('[_DemoEntryRepo] save id: $id');
    debugPrint('[_DemoEntryRepo] contentPlain: $contentPlain');
  }
}

class _DemoMediaStore {
  Future<String> put({
    required Stream<List<int>> bytes,
    required String entryId,
    required dynamic kind,
    required String mime,
    required int fileSize,
  }) async {
    debugPrint('[_DemoMediaStore] put for $entryId, size $fileSize, mime $mime');
    return 'media/demo-${DateTime.now().millisecondsSinceEpoch}.bin';
  }
}
