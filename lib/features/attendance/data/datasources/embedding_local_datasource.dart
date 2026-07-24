import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/face_embedding_model.dart';

abstract class EmbeddingLocalDatasource {
  Future<void> insertEmbedding(FaceEmbeddingModel embedding);
  Future<void> insertEmbeddings(List<FaceEmbeddingModel> embeddings);
  Future<List<FaceEmbeddingModel>> getEmbeddingsByPerson(String personId);
  Future<Map<String, List<FaceEmbeddingModel>>> getAllEmbeddingsGrouped();
  Future<int> getEmbeddingCount();
  Future<void> deleteEmbedding(int id);
  Future<void> deleteEmbeddingsByPerson(String personId);
  Future<void> deleteAllEmbeddings();
}

class EmbeddingLocalDatasourceImpl implements EmbeddingLocalDatasource {
  Future<Database> get _db => DatabaseHelper.instance.database;

  @override
  Future<void> insertEmbedding(FaceEmbeddingModel embedding) async {
    final db = await _db;
    await db.insert(
      'face_embeddings',
      embedding.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> insertEmbeddings(List<FaceEmbeddingModel> embeddings) async {
    final db = await _db;
    final batch = db.batch();
    for (final e in embeddings) {
      batch.insert('face_embeddings', e.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<FaceEmbeddingModel>> getEmbeddingsByPerson(
      String personId) async {
    final db = await _db;
    final rows = await db.query(
      'face_embeddings',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'created_at ASC',
    );
    return rows.map(FaceEmbeddingModel.fromMap).toList();
  }

  @override
  Future<Map<String, List<FaceEmbeddingModel>>>
      getAllEmbeddingsGrouped() async {
    final db = await _db;
    final rows = await db.query('face_embeddings', orderBy: 'created_at ASC');
    final grouped = <String, List<FaceEmbeddingModel>>{};
    for (final row in rows) {
      final model = FaceEmbeddingModel.fromMap(row);
      grouped.putIfAbsent(model.personId, () => []).add(model);
    }
    return grouped;
  }

  @override
  Future<int> getEmbeddingCount() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM face_embeddings');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> deleteEmbedding(int id) async {
    final db = await _db;
    await db.delete('face_embeddings', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteEmbeddingsByPerson(String personId) async {
    final db = await _db;
    await db.delete('face_embeddings',
        where: 'person_id = ?', whereArgs: [personId]);
  }

  @override
  Future<void> deleteAllEmbeddings() async {
    final db = await _db;
    await db.delete('face_embeddings');
  }
}
