// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_management_system/main.dart';

void main() {
  testWidgets('theme toggle updates material app mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('BAYN'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    final materialAppBefore = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(materialAppBefore.themeMode, ThemeMode.dark);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    final materialAppAfter = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(materialAppAfter.themeMode, ThemeMode.light);
  });
}
