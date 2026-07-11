import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/attendance/presentation/cubit/home_stats_cubit.dart';
import 'features/attendance/presentation/pages/home_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => di.sl<HomeStatsCubit>()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: const HomePage(enableAutoAttendanceRedirect: true),
        );
      },
    );
  }
}
