import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:abansermon/main.dart';

void main() {
  testWidgets('Basic dummy test to verify test setup', (WidgetTester tester) async {
    // 1. Wrap in ProviderScope because AbanApp is a ConsumerWidget
    await tester.pumpWidget(
      const ProviderScope(
        child: AbanApp(),
      ),
    );

    // 2. These expects will FAIL because your app does not have a '0' text or an add icon.
    // You should replace these with widgets that actually exist on your first screen 
    // (e.g., expect(find.text('Aban أبان'), findsOneWidget);)
    
    // expect(find.text('0'), findsOneWidget);
    // expect(find.text('1'), findsNothing);

    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // expect(find.text('1'), findsOneWidget);
    // expect(find.text('0'), findsNothing); // Fixed missing semicolon
  });
}
