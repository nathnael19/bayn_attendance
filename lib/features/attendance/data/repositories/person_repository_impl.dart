import 'package:flutter/foundation.dart';

import '../../domain/entities/person.dart';
import '../../domain/repositories/person_repository.dart';
import '../datasources/embedding_local_datasource.dart';
import '../datasources/face_recognition_datasource.dart';
import '../datasources/person_local_datasource.dart';
import '../datasources/person_remote_datasource.dart';
import '../models/face_embedding_model.dart';
import '../models/person_model.dart';

class PersonRepositoryImpl implements PersonRepository {
  final PersonLocalDatasource local;
  final PersonRemoteDatasource remote;
  final EmbeddingLocalDatasource embeddingLocal;
  final FaceRecognitionDatasource faceRecognition;

  PersonRepositoryImpl({
    required this.local,
    required this.remote,
    required this.embeddingLocal,
    required this.faceRecognition,
  });

  @override
  Future<Person> register(Person person, {bool saveImages = false}) async {
    Map<String, List<String>> finalPaths = {};

    if (saveImages) {
      finalPaths = await local.persistImages(
        person.employeeId,
        person.faceImagePaths,
      );
    }

    final modelToSave = PersonModel.fromEntity(
      person.copyWith(faceImagePaths: finalPaths),
    );

    final saved = await local.insertPerson(modelToSave);

    if (person.embeddings.isNotEmpty) {
      final embeddingModels = person.embeddings.map((e) {
        return FaceEmbeddingModel.fromEntity(e);
      }).toList();
      await embeddingLocal.insertEmbeddings(embeddingModels);
      await faceRecognition.reloadEmbeddings();
      debugPrint(
        '[PersonRepo] Saved ${embeddingModels.length} embeddings for ${person.name}',
      );
    }

    try {
      final serverId = await remote.registerPerson(
        saved,
        embeddings: person.embeddings.isNotEmpty
            ? person.embeddings
                  .map((e) => FaceEmbeddingModel.fromEntity(e))
                  .toList()
            : null,
      );
      if (saved.localId != null && serverId.isNotEmpty) {
        await local.updateSyncStatus(saved.localId!, serverId);
        return saved.copyWith(serverId: serverId, isSynced: true);
      }
    } catch (e) {
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
        final embeddings = await embeddingLocal.getEmbeddingsByPerson(
          person.employeeId,
        );
        final serverId = await remote.registerPerson(
          person,
          embeddings: embeddings.isNotEmpty ? embeddings : null,
        );
        if (person.localId != null && serverId.isNotEmpty) {
          await local.updateSyncStatus(person.localId!, serverId);
        }
      } catch (e) {
        debugPrint(
          '[PersonRepository] Sync retry failed for ${person.name}: $e',
        );
      }
    }
  }

  @override
  Future<SyncResult> pullFromServer() async {
    final employees = await remote.fetchAllEmployees();
    var embeddingCount = 0;

    final personModels = <PersonModel>[];
    final allEmbeddingModels = <FaceEmbeddingModel>[];

    for (final emp in employees) {
      personModels.add(
        PersonModel(
          serverId: emp.serverId.isNotEmpty ? emp.serverId : null,
          name: emp.name,
          employeeId: emp.employeeId,
          department: emp.department,
          registeredAt: emp.registeredAt,
          isSynced: true,
        ),
      );

      for (final rem in emp.embeddings) {
        allEmbeddingModels.add(
          FaceEmbeddingModel.fromRemote(
            personId: emp.employeeId,
            label: rem.label,
            vector: rem.vector,
            createdAt: emp.registeredAt,
          ),
        );
        embeddingCount++;
      }
    }

    await embeddingLocal.deleteAllEmbeddings();
    await local.replaceAllPersons(personModels);

    if (allEmbeddingModels.isNotEmpty) {
      await embeddingLocal.insertEmbeddings(allEmbeddingModels);
    }

    await faceRecognition.reloadEmbeddings();

    debugPrint(
      '[PersonRepo] Pulled ${personModels.length} employees with $embeddingCount embeddings',
    );

    return SyncResult(
      employeesSynced: personModels.length,
      embeddingsSynced: embeddingCount,
    );
  }

  @override
  Future<SyncResult> pushToServer() async {
    final unsynced = await local.getUnsyncedPersons();
    if (unsynced.isEmpty) {
      return const SyncResult(employeesSynced: 0, embeddingsSynced: 0);
    }

    int embeddingCount = 0;
    int pushedCount = 0;

    for (final person in unsynced) {
      try {
        final embeddings = await embeddingLocal.getEmbeddingsByPerson(
          person.employeeId,
        );
        final serverId = await remote.registerPerson(
          person,
          embeddings: embeddings.isNotEmpty ? embeddings : null,
        );
        if (person.localId != null && serverId.isNotEmpty) {
          await local.updateSyncStatus(person.localId!, serverId);
          pushedCount++;
          embeddingCount += embeddings.length;
        }
      } catch (e) {
        debugPrint(
          '[PersonRepository] Push to server failed for ${person.name}: $e',
        );
      }
    }

    return SyncResult(
      employeesSynced: pushedCount,
      embeddingsSynced: embeddingCount,
    );
  }

  @override
  Future<void> deletePerson(String employeeId) async {
    await embeddingLocal.deleteEmbeddingsByPerson(employeeId);
    await local.deletePersonByEmployeeId(employeeId);
    await faceRecognition.reloadEmbeddings();
  }
}
