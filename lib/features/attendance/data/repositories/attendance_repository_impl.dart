import 'package:flutter/foundation.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_record_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDatasource local;
  final AttendanceRemoteDatasource remote;

  const AttendanceRepositoryImpl({
    required this.local,
    required this.remote,
  });

  @override
  Future<AttendanceRecord> logAttendance(AttendanceRecord record) async {
    // 1️⃣  Always save locally first
    final model = AttendanceRecordModel.fromEntity(record);
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
  Future<List<AttendanceRecord>> getTodayRecords() =>
      local.getTodayRecords();

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
