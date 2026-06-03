import 'package:flutter/material.dart';
import 'package:dayz/app.dart';
import 'package:dayz/data/database.dart';
import 'package:dayz/data/repositories/entry_repo.dart';
import 'package:dayz/data/repositories/media_repo.dart';
import 'package:dayz/media/media_store.dart';
import 'package:dayz/data/repositories/editing_session_repo.dart';
import 'package:dayz/drafts/draft_coordinator.dart';
import 'package:dayz/drafts/draft_recovery_status.dart';
import 'package:dayz/data/time_zone_triple.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/ui/shell/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezoneData();

  final database = await AppDatabase.open(KeyProvider());
  registerTimelineEntryRepo(EntryRepo(database));

  final mediaRepo = MediaRepo(database);
  final mediaStore = MediaStore(
    keyProvider: KeyProvider(),
    mediaRepo: mediaRepo,
  );

  final coordinator = createProductionDraftCoordinator(database);
  await initializeDraftRecovery(coordinator);

  registerEditorServices(
    draftCoordinator: coordinator,
    mediaStore: mediaStore,
    mediaRepo: mediaRepo,
  );

  runApp(DayZApp(draftCoordinator: coordinator));
}

DraftCoordinator createProductionDraftCoordinator(AppDatabase database) {
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
