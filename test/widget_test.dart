// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('Material app can be created', (WidgetTester tester) async {
      // Build a simple MaterialApp to verify basic functionality
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test App')),
            body: const Center(child: Text('Hello World')),
          ),
        ),
      );

      // Verify that basic widgets work
      expect(find.text('Test App'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('Flutter is working correctly', (WidgetTester tester) async {
      // Create a simple counter app to test state management
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              int counter = 0;
              return Scaffold(
                body: Column(
                  children: [
                    Text('Count: $counter'),
                    ElevatedButton(
                      onPressed: () => setState(() => counter++),
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Increment'), findsOneWidget);
    });
  });
}
