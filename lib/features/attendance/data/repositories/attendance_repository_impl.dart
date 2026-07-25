import 'package:flutter/foundation.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_record_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDatasource local;
  final AttendanceRemoteDatasource remote;

  const AttendanceRepositoryImpl({required this.local, required this.remote});

  @override
  Future<AttendanceRecord> logAttendance(AttendanceRecord record) async {
    AttendanceRecord recordToSave = record;

    if (record.personId != null) {
      // 0️⃣  Load all scans the person has already done today
      final todayScans = await local.getPersonTodayScans(record.personId!);
      final completedTypes = todayScans.map((s) => s.scanType).toSet();

      // 1️⃣  Determine which scan type comes next in the sequence
      final ScanType nextType;
      if (!completedTypes.contains(ScanType.checkIn)) {
        nextType = ScanType.checkIn;
      } else if (!completedTypes.contains(ScanType.lunchBreak)) {
        nextType = ScanType.lunchBreak;
      } else if (!completedTypes.contains(ScanType.checkOut)) {
        nextType = ScanType.checkOut;
      } else {
        // All three scans are done — nothing more to record today
        final checkIn = todayScans.firstWhere(
          (s) => s.scanType == ScanType.checkIn,
        );
        throw DuplicateAttendanceException(
          personName: checkIn.personName,
          checkedInAt: checkIn.checkedInAt,
        );
      }

      recordToSave = record.copyWith(scanType: nextType);
    }

    // 2️⃣  Always save locally first
    final model = AttendanceRecordModel.fromEntity(recordToSave);
    final saved = await local.insert(model);

    // 2️⃣  Try backend (best-effort)
    try {
      final serverId = await remote.logAttendance(saved);
      if (saved.localId != null && serverId.isNotEmpty) {
        await local.markSynced(saved.localId!, serverId);
        return saved.copyWith(serverId: serverId, isSynced: true);
      }
    } catch (e) {
      debugPrint('[AttendanceRepository] Remote log skipped: $e');
    }

    return saved;
  }

  @override
  Future<List<AttendanceRecord>> getTodayRecords() => local.getTodayRecords();

  @override
  Future<List<AttendanceRecord>> getAllRecords() => local.getAllRecords();

  @override
  Future<TodayStats> getTodayStats() async {
    final records = await local.getTodayRecords();

    if (records.isEmpty) return TodayStats.empty;

    final avgConf =
        records.map((r) => r.confidence).reduce((a, b) => a + b) /
        records.length;

    // We don't track actual scan duration yet — use the confidence as a proxy
    // and keep the default 3s until the backend returns real timing data.
    // TODO: store scan duration in AttendanceRecord once backend provides it.
    return TodayStats(
      totalCheckedIn: records.length,
      averageConfidence: avgConf,
      averageScanSeconds: 3,
    );
  }

  @override
  Future<void> syncPending() async {
    final unsynced = await local.getUnsynced();
    if (unsynced.isEmpty) return;
    await remote.syncRecords(unsynced);
  }
}
