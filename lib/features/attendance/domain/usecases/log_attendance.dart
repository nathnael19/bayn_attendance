import '../entities/attendance_record.dart';
import '../repositories/attendance_repository.dart';

class LogAttendance {
  final AttendanceRepository repository;
  const LogAttendance(this.repository);
  Future<AttendanceRecord> call(AttendanceRecord record) =>
      repository.logAttendance(record);
}
