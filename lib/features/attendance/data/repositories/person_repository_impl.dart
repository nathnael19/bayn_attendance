import 'package:flutter/foundation.dart';

import '../../domain/entities/person.dart';
import '../../domain/repositories/person_repository.dart';
import '../datasources/person_local_datasource.dart';
import '../datasources/person_remote_datasource.dart';
import '../models/person_model.dart';

class PersonRepositoryImpl implements PersonRepository {
  final PersonLocalDatasource local;
  final PersonRemoteDatasource remote;

  const PersonRepositoryImpl({
    required this.local,
    required this.remote,
  });

  @override
  Future<Person> register(Person person) async {
    // 1️⃣  Move photos from camera temp → permanent storage
    final permanentPaths = await local.persistImages(
      person.employeeId,
      person.faceImagePaths,
    );

    final modelToSave = PersonModel.fromEntity(
      person.copyWith(faceImagePaths: permanentPaths),
    );

    // 2️⃣  Always save locally first — guaranteed even without internet
    final saved = await local.insertPerson(modelToSave);

    // 3️⃣  Try to push to backend (best-effort)
    try {
      final serverId = await remote.registerPerson(saved);
      if (saved.localId != null && serverId.isNotEmpty) {
        await local.updateSyncStatus(saved.localId!, serverId);
        return saved.copyWith(serverId: serverId, isSynced: true);
      }
    } catch (e) {
      // Backend unavailable or not configured yet — that's fine.
      // The record is already local; syncPending() can retry later.
      debugPrint('[PersonRepository] Remote sync skipped: $e');
    }

    return saved;
  }

  @override
  Future<List<Person>> getAllPersons() async {
    return local.getAllPersons();
  }

  @override
  Future<void> syncPending() async {
    final unsynced = await local.getUnsyncedPersons();
    if (unsynced.isEmpty) return;

    for (final person in unsynced) {
      try {
        final serverId = await remote.registerPerson(person);
        if (person.localId != null && serverId.isNotEmpty) {
          await local.updateSyncStatus(person.localId!, serverId);
        }
      } catch (e) {
        debugPrint('[PersonRepository] Sync retry failed for ${person.name}: $e');
      }
    }
  }
}
