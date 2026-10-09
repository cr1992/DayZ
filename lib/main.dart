// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:dayz/app.dart';
import 'package:dayz/app/app_services.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/draft_recovery_status.dart';
import 'package:dayz/data/time_zone_triple.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezoneData();

  final services = await AppServices.open();
  DraftCoordinator? coordinator;
  if (services != null) {
    coordinator = createDraftCoordinator(services);
    await initializeDraftRecovery(coordinator);
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
