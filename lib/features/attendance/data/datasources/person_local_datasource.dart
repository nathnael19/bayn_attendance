import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/person_model.dart';

abstract class PersonLocalDatasource {
  Future<PersonModel> insertPerson(PersonModel person);
  Future<List<PersonModel>> getAllPersons();
  Future<void> updateSyncStatus(int localId, String serverId);
  Future<List<PersonModel>> getUnsyncedPersons();
  Future<Map<String, List<String>>> persistImages(
    String personEmployeeId,
    Map<String, List<String>> tempPaths,
  );
  Future<void> replaceAllPersons(List<PersonModel> persons);
  Future<int> deleteAllPersons();
}

class PersonLocalDatasourceImpl implements PersonLocalDatasource {
  Future<Database> get _db => DatabaseHelper.instance.database;

  @override
  Future<PersonModel> insertPerson(PersonModel person) async {
    final db = await _db;
    final id = await db.insert(
      'persons',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return PersonModel(
      localId: id,
      serverId: person.serverId,
      name: person.name,
      employeeId: person.employeeId,
      department: person.department,
      faceImagePaths: person.faceImagePaths,
      registeredAt: person.registeredAt,
      isSynced: person.isSynced,
    );
  }

  @override
  Future<List<PersonModel>> getAllPersons() async {
    final db = await _db;
    final rows = await db.query('persons', orderBy: 'registered_at DESC');
    return rows.map(PersonModel.fromMap).toList();
  }

  @override
  Future<void> updateSyncStatus(int localId, String serverId) async {
    final db = await _db;
    await db.update(
      'persons',
      {'server_id': serverId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  @override
  Future<List<PersonModel>> getUnsyncedPersons() async {
    final db = await _db;
    final rows = await db.query(
      'persons',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return rows.map(PersonModel.fromMap).toList();
  }

  @override
  Future<Map<String, List<String>>> persistImages(
    String personEmployeeId,
    Map<String, List<String>> tempPaths,
  ) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final personDir = Directory(
      p.join(docsDir.path, 'bayn_faces', personEmployeeId),
    );
    await personDir.create(recursive: true);

    final permanent = <String, List<String>>{};

    for (final entry in tempPaths.entries) {
      final angle = entry.key;
      final paths = entry.value;
      permanent[angle] = [];

      for (var i = 0; i < paths.length; i++) {
        final ext = p.extension(paths[i]).isNotEmpty
            ? p.extension(paths[i])
            : '.jpg';
        final destPath = p.join(personDir.path, '${angle}_$i$ext');
        await File(paths[i]).copy(destPath);
        permanent[angle]!.add(destPath);
      }
    }

    return permanent;
  }

  @override
  Future<void> replaceAllPersons(List<PersonModel> persons) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('persons');
      for (final p in persons) {
        await txn.insert('persons', p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<int> deleteAllPersons() async {
    final db = await _db;
    return db.delete('persons');
  }
}
