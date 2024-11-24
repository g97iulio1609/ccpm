import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 24,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

// Variante specifica per le action cards (con icone di azione)
class ActionCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final List<Widget> actions;
  final List<Widget>? bottomContent;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry actionsPadding;

  const ActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.actions,
    this.bottomContent,
    this.onTap,
    this.contentPadding = const EdgeInsets.all(24),
    this.actionsPadding = const EdgeInsets.symmetric(horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: contentPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: actionsPadding,
                  child: Row(
                    children: actions.map((action) {
                      final index = actions.indexOf(action);
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index > 0 ? 8.0 : 0,
                        ),
                        child: action,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          if (bottomContent != null) ...[
            const SizedBox(height: 20),
            Padding(
              padding: contentPadding,
              child: Row(
                children: bottomContent!.map((content) {
                  final index = bottomContent!.indexOf(content);
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index > 0 ? 16.0 : 0,
                    ),
                    child: content,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Helper widget per creare un pulsante icona con sfondo colorato
class IconButtonWithBackground extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final EdgeInsetsGeometry padding;

  const IconButtonWithBackground({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 20,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: size),
        onPressed: onPressed,
        color: color,
        padding: padding,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }
} 