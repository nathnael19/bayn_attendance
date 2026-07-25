import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceLocalDatasource {
  Future<AttendanceRecordModel> insert(AttendanceRecordModel record);
  Future<List<AttendanceRecordModel>> getTodayRecords();
  Future<List<AttendanceRecordModel>> getAllRecords();
  Future<List<AttendanceRecordModel>> getUnsynced();
  Future<void> markSynced(int localId, String serverId);

  /// Returns the existing record for today if the person already marked attendance, null otherwise.
  Future<AttendanceRecordModel?> getTodayRecordForPerson(String personId);

  /// Returns ALL scan records for a person today, ordered by time ascending.
  /// Used by the repository to determine which scan type comes next.
  Future<List<AttendanceRecordModel>> getPersonTodayScans(String personId);
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
      checkedOutAt: record.checkedOutAt,
      status: record.status,
      shiftId: record.shiftId,
      location: record.location,
      isSynced: record.isSynced,
    );
  }

  @override
  Future<List<AttendanceRecordModel>> getTodayRecords() async {
    final db = await _db;
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final end = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

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

  @override
  Future<AttendanceRecordModel?> getTodayRecordForPerson(
    String personId,
  ) async {
    final db = await _db;
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final end = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

    final rows = await db.query(
      'attendance_records',
      where: 'person_id = ? AND checked_in_at BETWEEN ? AND ?',
      whereArgs: [personId, start, end],
      orderBy: 'checked_in_at ASC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AttendanceRecordModel.fromMap(rows.first);
  }

  @override
  Future<List<AttendanceRecordModel>> getPersonTodayScans(
    String personId,
  ) async {
    final db = await _db;
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final end = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

    final rows = await db.query(
      'attendance_records',
      where: 'person_id = ? AND checked_in_at BETWEEN ? AND ?',
      whereArgs: [personId, start, end],
      orderBy: 'checked_in_at ASC',
    );
    return rows.map(AttendanceRecordModel.fromMap).toList();
  }
}
