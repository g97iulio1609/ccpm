import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/Main/app_theme.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryGold.withAlpha(30),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
              border: Border.all(
                color: _isFocused
                    ? AppTheme.primaryGold
                    : colorScheme.outline.withAlpha(40),
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: AppTheme.spacing.sm,
                    left: AppTheme.spacing.sm,
                    right: AppTheme.spacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 16,
                          color: AppTheme.primaryGold,
                        ),
                        SizedBox(width: 6),
                      ],
                      Text(
                        widget.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: AppTheme.spacing.sm,
                    right: AppTheme.spacing.sm,
                    bottom: AppTheme.spacing.sm,
                  ),
                  child: Focus(
                    onFocusChange: (focused) {
                      setState(() {
                        _isFocused = focused;
                      });
                      if (focused) {
                        _animationController.forward();
                        HapticFeedback.lightImpact();
                      } else {
                        _animationController.reverse();
                      }
                    },
                    child: TextField(
                      controller: widget.controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d*'),
                        ),
                      ],
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 32,
                      ),
                      cursorColor: AppTheme.primaryGold,
                      decoration: InputDecoration(
                        hintText: widget.hint ?? '',
                        hintStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white.withAlpha(60),
                          fontWeight: FontWeight.w600,
                          fontSize: 32,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(
                          top: AppTheme.spacing.xxs,
                          bottom: AppTheme.spacing.xxs,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
