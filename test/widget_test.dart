import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zad_mobile/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ZadApp(
        home: Scaffold(
          body: Center(
            child: Text('زاد التعليمية'),
          ),
        ),
      ),
    );

    expect(find.text('زاد التعليمية'), findsOneWidget);
  });
}
