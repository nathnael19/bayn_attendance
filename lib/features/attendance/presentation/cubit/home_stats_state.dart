import 'package:equatable/equatable.dart';
import '../../domain/repositories/attendance_repository.dart';

abstract class HomeStatsState extends Equatable {
  const HomeStatsState();
  @override
  List<Object?> get props => [];
}

class HomeStatsInitial extends HomeStatsState {
  const HomeStatsInitial();
}

class HomeStatsLoading extends HomeStatsState {
  const HomeStatsLoading();
}

class HomeStatsLoaded extends HomeStatsState {
  final TodayStats stats;
  const HomeStatsLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class HomeStatsError extends HomeStatsState {
  final String message;
  const HomeStatsError(this.message);
  @override
  List<Object?> get props => [message];
}
