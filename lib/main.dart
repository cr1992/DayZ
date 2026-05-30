import 'package:flutter/material.dart';
import 'package:dayz/app.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/editing_session_repo.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/draft_recovery_status.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/security/key_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezoneData();

  final coordinator = await createProductionDraftCoordinator();
  await initializeDraftRecovery(coordinator);

  runApp(DayZApp(draftCoordinator: coordinator));
}

Future<DraftCoordinator> createProductionDraftCoordinator() async {
  final database = await AppDatabase.open(KeyProvider());
  final repo = EditingSessionRepo(database);
  return DraftCoordinator(store: EditingSessionDraftStore(repo));
}

Future<DraftRecoveryStatus> initializeDraftRecovery(
  DraftCoordinator coordinator,
) async {
  final status = await coordinator.startupCheck();
  DraftRecoveryHolder.update(status);
  return status;
}
