import 'package:alphanessone/UI/components/kpi_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KpiBadge mostra testo e icona', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: KpiBadge(
              text: '75 kg',
              icon: Icons.fitness_center,
            ),
          ),
        ),
      ),
    );

    expect(find.text('75 kg'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });
}


