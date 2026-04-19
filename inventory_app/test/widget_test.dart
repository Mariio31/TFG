// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Build the login screen and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Verify that the title is displayed.
    expect(find.text('Inventory App'), findsOneWidget);

    // Verify that there are two text fields (email and password).
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify that there is a login button.
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
