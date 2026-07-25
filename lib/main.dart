import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/attendance/data/datasources/face_recognition_datasource.dart';
import 'features/attendance/presentation/cubit/home_stats_cubit.dart';
import 'features/attendance/presentation/pages/home_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'injection_container.dart' as di;

void main() async {
  // Keep native splash screen during initialization
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await di.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => di.sl<HomeStatsCubit>()..load()),
      ],
      child: MyApp(
        enableSplash: true,
        onInitialize: () =>
            di.sl<FaceRecognitionDatasource>().reloadEmbeddings(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool enableSplash;
  final Future<void> Function()? onInitialize;

  const MyApp({super.key, this.enableSplash = false, this.onInitialize});

  Widget _buildHome(BuildContext context) {
    return const HomePage(enableAutoAttendanceRedirect: true);
  }

  Widget _buildHomeOrSplash(BuildContext context) {
    if (!enableSplash) return _buildHome(context);
    return SplashPage(
      onInitialize: onInitialize,
      destinationBuilder: (_) => _buildHome(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'BAYN Attendance',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: _buildHomeOrSplash(context),
        );
      },
    );
  }
}
