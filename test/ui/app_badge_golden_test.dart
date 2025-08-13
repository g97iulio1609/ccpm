import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppBadge contrast and variants smoke', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppBadge(label: 'Primary', status: AppBadgeStatus.primary),
                AppBadge(label: 'Success', status: AppBadgeStatus.success),
                AppBadge(label: 'Warning', status: AppBadgeStatus.warning),
                AppBadge(label: 'Error', status: AppBadgeStatus.error),
                AppBadge(label: 'Info', status: AppBadgeStatus.info),
                AppBadge(
                  label: 'Outline',
                  status: AppBadgeStatus.primary,
                  variant: AppBadgeVariant.outline,
                ),
                AppBadge(
                  label: 'Subtle',
                  status: AppBadgeStatus.primary,
                  variant: AppBadgeVariant.subtle,
                ),
                AppBadge(
                  label: 'Gradient',
                  status: AppBadgeStatus.primary,
                  variant: AppBadgeVariant.gradient,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Gradient'), findsOneWidget);
  });
}
