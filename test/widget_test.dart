import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_management_system/core/theme/theme_cubit.dart';
import 'package:attendance_management_system/main.dart';

void main() {
  testWidgets('homepage theme and settings controls work', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ThemeCubit(),
        child: const MyApp(),
      ),
    );

    expect(find.text('BAYN'), findsOneWidget);
    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();

    final darkMaterialApp = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(darkMaterialApp.themeMode, ThemeMode.dark);
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Open settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });
}
