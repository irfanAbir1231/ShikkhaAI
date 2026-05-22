import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shikkhaai/app.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ShikkhaAIApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
