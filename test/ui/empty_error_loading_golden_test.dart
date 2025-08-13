import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppCard empty/error/loading visual smoke', (tester) async {
    final theme = AppTheme.darkTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              AppCard(
                title: 'Nessun elemento',
                subtitle: 'Aggiungi il primo elemento per iniziare',
                leadingIcon: Icons.info_outline,
                child: SizedBox.shrink(),
              ),
              SizedBox(height: 16),
              AppCard(
                title: 'Errore',
                subtitle: 'Si è verificato un problema, riprova',
                leadingIcon: Icons.error_outline,
                child: SizedBox.shrink(),
              ),
              SizedBox(height: 16),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Nessun elemento'), findsOneWidget);
    expect(find.text('Errore'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
