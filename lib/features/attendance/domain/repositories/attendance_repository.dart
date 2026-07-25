import '../entities/attendance_record.dart';

/// Thrown when a person attempts to mark attendance more than once in a day.
class DuplicateAttendanceException implements Exception {
  final String personName;
  final DateTime checkedInAt;

  const DuplicateAttendanceException({
    required this.personName,
    required this.checkedInAt,
  });
}

/// Stats for the home page — all derived from local data.
class TodayStats {
  final int totalCheckedIn;
  final double averageConfidence; // used as accuracy proxy
  final double averageScanSeconds;

  const TodayStats({
    required this.totalCheckedIn,
    required this.averageConfidence,
    required this.averageScanSeconds,
  });

  /// Formatted accuracy string, e.g. "98.5%"
  String get accuracyLabel =>
      '${(averageConfidence * 100).toStringAsFixed(1)}%';

  /// Formatted scan time string, e.g. "< 2s"
  String get scanTimeLabel => '< ${averageScanSeconds.toStringAsFixed(0)}s';

  static const TodayStats empty = TodayStats(
    totalCheckedIn: 0,
    averageConfidence: 0,
    averageScanSeconds: 3,
  );
}

abstract class AttendanceRepository {
  /// Save a successful check-in locally and push to backend.
  Future<AttendanceRecord> logAttendance(AttendanceRecord record);

  /// Get all attendance records for today (local).
  Future<List<AttendanceRecord>> getTodayRecords();

  /// Get all records ever (local).
  Future<List<AttendanceRecord>> getAllRecords();

  /// Compute stats for today from local data.
  Future<TodayStats> getTodayStats();

  /// Push un-synced records to backend.
  Future<void> syncPending();
}
