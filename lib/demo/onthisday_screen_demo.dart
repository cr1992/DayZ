// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../ui/components.dart';
import '../ui/onthisday/onthisday_screen.dart';
import '../ui/onthisday/onthisday_view_model.dart';
import '../ui/theme/dayz_tokens.g.dart';

/// Debug Home demo：往年今日屏 `default` / `empty` 两态（内存假 VM，不连真实
/// 库、不触发缩略图生成）。
///
/// Author: @Ray
class OnThisDayScreenDemo extends StatefulWidget {
  const OnThisDayScreenDemo({super.key});

  static const Key defaultSegmentKey = ValueKey<String>('otd-demo-default');
  static const Key emptySegmentKey = ValueKey<String>('otd-demo-empty');

  @override
  State<OnThisDayScreenDemo> createState() => _OnThisDayScreenDemoState();
}

enum _OnThisDayDemoState { withEntries, empty }

class _OnThisDayScreenDemoState extends State<OnThisDayScreenDemo> {
  _OnThisDayDemoState _state = _OnThisDayDemoState.withEntries;

  @override
  Widget build(BuildContext context) {
    final data = _state == _OnThisDayDemoState.withEntries
        ? _demoData()
        : OnThisDayData(date: _demoToday, totalCount: 0, groups: const []);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(DayzSpacing.s4),
              child: DayzSegmented<_OnThisDayDemoState>(
                value: _state,
                onChanged: (value) => setState(() => _state = value),
                segments: const [
                  DayzSegment(
                    value: _OnThisDayDemoState.withEntries,
                    child: Text('有内容', key: OnThisDayScreenDemo.defaultSegmentKey),
                  ),
                  DayzSegment(
                    value: _OnThisDayDemoState.empty,
                    child: Text('空态', key: OnThisDayScreenDemo.emptySegmentKey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: OnThisDayScreen(
                key: ValueKey(_state),
                data: data,
                onOpenEntry: (id) => _toast(context, '打开 $id（demo 不跳阅读页）'),
                onOpenMemory: (date) =>
                    _toast(context, '回忆卡片 ${date.month}/${date.day}（demo）'),
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String text) {
    DayzToast.show(context, text, DayzToastTone.info);
  }
}

final DateTime _demoToday = DateTime(2026, 5, 29);

OnThisDayData _demoData() {
  final cover = AssetImage(Assets.editor.demoImage.path);
  return OnThisDayData(
    date: _demoToday,
    totalCount: 4,
    groups: [
      YearGroup(
        year: 2024,
        yearsAgo: 2,
        entries: [
          EntryCardVM(
            entryId: 'demo-2024',
            title: '搬家第一夜',
            excerpt: '纸箱还没拆完，先把台灯和被子找了出来。新房间的风从阳台进来，带着一点桂花的味道。',
            date: DateTime(2024, 5, 29),
            place: '上海',
          ),
        ],
      ),
      YearGroup(
        year: 2021,
        yearsAgo: 5,
        entries: [
          EntryCardVM(
            entryId: 'demo-2021',
            title: '毕业那天的海',
            excerpt: '论文答辩完，几个人开车去看了海。谁也没说话，就那样坐到太阳落下去。',
            date: DateTime(2021, 5, 29),
            place: '青岛',
            favorite: true,
            coverImage: cover,
          ),
        ],
      ),
      YearGroup(
        year: 2019,
        yearsAgo: 7,
        entries: [
          EntryCardVM(
            entryId: 'demo-2019-a',
            title: '第一次一个人做饭',
            excerpt: '番茄炒蛋放多了糖，但还是吃完了。',
            date: DateTime(2019, 5, 29),
          ),
          EntryCardVM(
            entryId: 'demo-2019-b',
            title: '晚上的雨',
            excerpt: '下班路上下起了雨，在便利店门口站了很久。',
            date: DateTime(2019, 5, 29),
          ),
        ],
      ),
    ],
  );
}
