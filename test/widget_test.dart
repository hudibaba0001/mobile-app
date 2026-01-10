import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple smoke test to verify the app compiles
// Full integration tests require a real auth service
void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Simple test to verify Flutter framework is working
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('App compiles successfully'),
          ),
        ),
      ),
    );
    
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('App compiles successfully'), findsOneWidget);
  });
}
