// Patrol 冒烟用例：在真机/模拟器上启动真实 DayZ app（会打开加密 SQLCipher 库、
// 注册仓储、初始化草稿恢复），验证 Patrol 原生测试管线打通 + `$` finder 可用。
//
// 跑法（iOS 模拟器，patrol_cli 4.x 默认就扫 patrol_test/ 目录）：
//   patrol test -d <ios-sim-id>
//
// 注意：patrol_cli 4.0 起默认测试目录 = patrol_test/（不再是 integration_test/），
// 放错目录会触发 test_bundle 路径拼接 bug。vanilla 的 argon2id_ffi 测试仍留在
// integration_test/，两条轨道互不干扰。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:dayz/main.dart' as app;

void main() {
  patrolTest('DayZ 冷启动冒烟：真 app 启动并渲染外壳', ($) async {
    // 启动真实生产入口：异步打开加密数据库、注册 Timeline 仓储、初始化草稿恢复。
    await app.main();
    await $.pumpAndSettle();

    // `$` 即 PatrolTester：自带自动等待，替代 find.byType(...) + 反复 pumpAndSettle。
    await $(MaterialApp).waitUntilVisible();
    expect($(MaterialApp).visible, isTrue);
    expect($(Scaffold).visible, isTrue);
  });
}
