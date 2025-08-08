import 'package:alphanessone/UI/components/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppCard rende header, child e footer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            header: const Text('Header'),
            footer: const Text('Footer'),
            child: const Text('Content'),
          ),
        ),
      ),
    );

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
  });
}


