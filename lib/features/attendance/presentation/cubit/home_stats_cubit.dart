import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_today_stats.dart';
import 'home_stats_state.dart';

class HomeStatsCubit extends Cubit<HomeStatsState> {
  final GetTodayStats getTodayStats;

  HomeStatsCubit({required this.getTodayStats})
      : super(const HomeStatsInitial());

  Future<void> load() async {
    emit(const HomeStatsLoading());
    try {
      final stats = await getTodayStats();
      emit(HomeStatsLoaded(stats));
    } catch (e) {
      emit(HomeStatsError(e.toString()));
    }
  }
}
