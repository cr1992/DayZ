// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:dayz/app/timeline_repository_adapter.dart';
import 'package:dayz/ui/timeline/timeline_controller.dart';
import 'package:dayz/ui/timeline/timeline_page.dart';

/// 生产路径的时间线：持有 [TimelineController] 的生命周期（建、首载、切本、释放）。
///
/// Author: @Ray
class TimelineHost extends StatefulWidget {
  const TimelineHost({
    super.key,
    required this.repo,
    this.journalId,
    this.contentRevision,
  });

  final TimelineRepositoryAdapter repo;

  /// 条目内容变更信号；变化时从头重载当前日记本。
  final ValueListenable<int>? contentRevision;

  /// 当前日记本；null 表示「全部」。
  final String? journalId;

  @override
  State<TimelineHost> createState() => _TimelineHostState();
}

class _TimelineHostState extends State<TimelineHost> {
  late TimelineController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimelineController(repo: widget.repo);
    _controller.loadInitial(widget.journalId);
    widget.contentRevision?.addListener(_reload);
  }

  void _reload() {
    _controller.loadInitial(widget.journalId);
  }

  @override
  void didUpdateWidget(TimelineHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentRevision != widget.contentRevision) {
      oldWidget.contentRevision?.removeListener(_reload);
      widget.contentRevision?.addListener(_reload);
    }
    if (!identical(oldWidget.repo, widget.repo)) {
      _controller.dispose();
      _controller = TimelineController(repo: widget.repo);
      _controller.loadInitial(widget.journalId);
      return;
    }
    if (oldWidget.journalId != widget.journalId) {
      _controller.switchJournal(widget.journalId);
    }
  }

  @override
  void dispose() {
    widget.contentRevision?.removeListener(_reload);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TimelinePage(controller: _controller);
  }
}
