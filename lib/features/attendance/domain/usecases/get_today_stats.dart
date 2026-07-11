import '../repositories/attendance_repository.dart';

class GetTodayStats {
  final AttendanceRepository repository;
  const GetTodayStats(this.repository);
  Future<TodayStats> call() => repository.getTodayStats();
}
