import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceLocalDatasource {
  Future<AttendanceRecordModel> insert(AttendanceRecordModel record);
  Future<List<AttendanceRecordModel>> getTodayRecords();
  Future<List<AttendanceRecordModel>> getAllRecords();
  Future<List<AttendanceRecordModel>> getUnsynced();
  Future<void> markSynced(int localId, String serverId);
}

class AttendanceLocalDatasourceImpl implements AttendanceLocalDatasource {
  Future<Database> get _db => DatabaseHelper.instance.database;

  @override
  Future<AttendanceRecordModel> insert(AttendanceRecordModel record) async {
    final db = await _db;
    final id = await db.insert(
      'attendance_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return AttendanceRecordModel(
      localId: id,
      serverId: record.serverId,
      personId: record.personId,
      personName: record.personName,
      department: record.department,
      confidence: record.confidence,
      checkedInAt: record.checkedInAt,
      isSynced: record.isSynced,
    );
  }

  @override
  Future<List<AttendanceRecordModel>> getTodayRecords() async {
    final db = await _db;
    final today = DateTime.now();
    final start =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59)
        .toIso8601String();

    final rows = await db.query(
      'attendance_records',
      where: 'checked_in_at BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'checked_in_at DESC',
    );
    return rows.map(AttendanceRecordModel.fromMap).toList();
  }

  @override
  Future<List<AttendanceRecordModel>> getAllRecords() async {
    final db = await _db;
    final rows = await db.query(
      'attendance_records',
      orderBy: 'checked_in_at DESC',
    );
    return rows.map(AttendanceRecordModel.fromMap).toList();
  }

  @override
  Future<List<AttendanceRecordModel>> getUnsynced() async {
    final db = await _db;
    final rows = await db.query(
      'attendance_records',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return rows.map(AttendanceRecordModel.fromMap).toList();
  }

  @override
  Future<void> markSynced(int localId, String serverId) async {
    final db = await _db;
    await db.update(
      'attendance_records',
      {'server_id': serverId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
}
