import 'package:flutter/material.dart';
import 'package:dayz/app.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/app/router_ports.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/draft_recovery_status.dart';
import 'package:dayz/data/time_zone_triple.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezoneData();

  // 组合根：进程内只打开一次加密库；打不开（如主密码模式未解锁）时 services 为
  // null，各屏路由退回占位，不崩溃。
  final services = await AppServices.open();
  DraftCoordinator? coordinator;
  if (services != null) {
    coordinator = createDraftCoordinator(services);
    await initializeDraftRecovery(coordinator);
    bindRouterPorts(services, draftCoordinator: coordinator);
  }

  runApp(DayZApp(services: services, draftCoordinator: coordinator));
}

DraftCoordinator createDraftCoordinator(AppServices services) {
  return DraftCoordinator(
    store: EditingSessionDraftStore(services.editingSessions),
  );
}

Future<DraftRecoveryStatus> initializeDraftRecovery(
  DraftCoordinator coordinator,
) async {
  final status = await coordinator.startupCheck();
  DraftRecoveryHolder.update(status);
  return status;
}
