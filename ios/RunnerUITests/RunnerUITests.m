@import XCTest;
@import patrol;
@import ObjectiveC.runtime;

// Patrol iOS 原生测试入口：该宏会在运行期为每个 Dart 用例动态生成一个 XCTest 方法，
// 由 XCUITest 拉起 app 并桥接到 Dart 侧的 patrolTest。
PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
