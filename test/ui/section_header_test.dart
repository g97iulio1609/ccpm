import 'package:alphanessone/UI/components/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SectionHeader mostra title e subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: 'Titolo',
            subtitle: 'Sottotitolo',
          ),
        ),
      ),
    );

    expect(find.text('Titolo'), findsOneWidget);
    expect(find.text('Sottotitolo'), findsOneWidget);
  });
}


