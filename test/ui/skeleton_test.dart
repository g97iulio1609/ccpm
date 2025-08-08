import 'package:alphanessone/UI/components/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkeletonList costruisce un numero corretto di items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonList(itemCount: 3),
        ),
      ),
    );

    expect(find.byType(SkeletonCard), findsNWidgets(3));
  });
}


