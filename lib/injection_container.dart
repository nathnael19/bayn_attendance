import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'features/attendance/data/datasources/attendance_local_datasource.dart';
import 'features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'features/attendance/data/datasources/embedding_local_datasource.dart';
import 'features/attendance/data/datasources/face_recognition_datasource.dart';
import 'features/attendance/data/datasources/person_local_datasource.dart';
import 'features/attendance/data/datasources/person_remote_datasource.dart';
import 'features/attendance/data/repositories/attendance_repository_impl.dart';
import 'features/attendance/data/repositories/person_repository_impl.dart';
import 'features/attendance/data/services/tflite_embedding_extractor.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/repositories/person_repository.dart';
import 'features/attendance/domain/services/face_embedding_extractor.dart';
import 'features/attendance/domain/usecases/get_all_persons.dart';
import 'features/attendance/domain/usecases/get_today_stats.dart';
import 'features/attendance/domain/usecases/log_attendance.dart';
import 'features/attendance/domain/usecases/register_person.dart';
import 'features/attendance/presentation/cubit/attendance_cubit.dart';
import 'features/attendance/presentation/cubit/home_stats_cubit.dart';
import 'features/attendance/presentation/cubit/register_cubit.dart';
import 'features/attendance/presentation/cubit/users_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── External ──────────────────────────────────────────────
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // ── Services ──────────────────────────────────────────────
  sl.registerLazySingleton<FaceEmbeddingExtractor>(
    () => TfliteEmbeddingExtractor(),
  );

  // ── Datasources ───────────────────────────────────────────
  sl.registerLazySingleton<PersonLocalDatasource>(
    () => PersonLocalDatasourceImpl(),
  );
  sl.registerLazySingleton<PersonRemoteDatasource>(
    () => PersonRemoteDatasourceImpl(httpClient: sl()),
  );
  sl.registerLazySingleton<AttendanceLocalDatasource>(
    () => AttendanceLocalDatasourceImpl(),
  );
  sl.registerLazySingleton<AttendanceRemoteDatasource>(
    () => AttendanceRemoteDatasourceImpl(httpClient: sl()),
  );
  sl.registerLazySingleton<FaceRecognitionDatasource>(
    () => FaceRecognitionDatasourceImpl(
      personLocalDatasource: sl(),
      embeddingLocalDatasource: sl(),
      embeddingExtractor: sl(),
    ),
  );
  sl.registerLazySingleton<EmbeddingLocalDatasource>(
    () => EmbeddingLocalDatasourceImpl(),
  );

  // ── Repositories ──────────────────────────────────────────
  sl.registerLazySingleton<PersonRepository>(
    () => PersonRepositoryImpl(
      local: sl(),
      remote: sl(),
      embeddingLocal: sl(),
      faceRecognition: sl(),
    ),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(local: sl(), remote: sl()),
  );

  // ── Use cases ─────────────────────────────────────────────
  sl.registerLazySingleton(() => RegisterPerson(sl()));
  sl.registerLazySingleton(() => LogAttendance(sl()));
  sl.registerLazySingleton(() => GetTodayStats(sl()));
  sl.registerLazySingleton(() => GetAllPersons(sl()));

  // ── Cubits (factory — fresh instance each time) ───────────
  sl.registerFactory(
    () => AttendanceCubit(faceRecognition: sl(), logAttendance: sl()),
  );
  sl.registerFactory(
    () => RegisterCubit(
      registerPersonUseCase: sl(),
      embeddingExtractor: sl(),
    ),
  );
  sl.registerFactory(() => HomeStatsCubit(getTodayStats: sl()));
  sl.registerFactory(() => UsersCubit(repository: sl()));
}
