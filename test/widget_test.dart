// Basic Flutter widget test for WhaleSkin app structure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:whaleskin/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app initializes without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
