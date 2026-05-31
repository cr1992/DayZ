import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';

import '../l10n/localized_test_app.dart';

void main() {
  testWidgets('Debug Home renders list and navigates to demo', (
    WidgetTester tester,
  ) async {
    final mockEntries = [
      DemoEntry(
        title: 'Mock Demo Title',
        subtitle: 'Mock Subtitle',
        builder: (context) =>
            const Scaffold(body: Center(child: Text('Mock Demo Content'))),
      ),
    ];

    await tester.pumpWidget(
      localizedTestApp(child: DebugHome(entries: mockEntries)),
    );

    // Verify list item is rendered
    expect(find.text('Mock Demo Title'), findsOneWidget);
    expect(find.text('Mock Subtitle'), findsOneWidget);

    // Tap to navigate
    await tester.tap(find.text('Mock Demo Title'));
    await tester.pumpAndSettle();

    // Verify navigation
    expect(find.text('Mock Demo Content'), findsOneWidget);
  });

  testWidgets('Debug Home renders Hello Demo from real demos list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));

    expect(find.text('Hello Demo'), findsOneWidget);

    await tester.tap(find.text('Hello Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, DayZ demo!'), findsOneWidget);
  });
}
