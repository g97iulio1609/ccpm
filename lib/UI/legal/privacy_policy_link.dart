import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/Main/routes.dart';

class PrivacyPolicyLink extends StatelessWidget {
  final TextStyle? textStyle;
  final bool showIcon;
  final String text;
  final bool isCompact;

  const PrivacyPolicyLink({
    super.key,
    this.textStyle,
    this.showIcon = true,
    this.text = 'Privacy Policy',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return InkWell(
        onTap: () => context.push(Routes.privacyPolicy),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  Icons.privacy_tip_outlined,
                  size: 16,
                  color: textStyle?.color ?? theme.primaryColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style:
                    textStyle ??
                    TextStyle(
                      color: theme.primaryColor,
                      decoration: TextDecoration.underline,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Design prominente per la schermata di login
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(Routes.privacyPolicy),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(
                  alpha: theme.colorScheme.outline.a * 0.3,
                ),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface.withValues(alpha: theme.colorScheme.surface.a * 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: theme.colorScheme.primary.a * 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Leggi la nostra informativa',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Rimosso: bottone non utilizzato, mantenuto solo il link principale
