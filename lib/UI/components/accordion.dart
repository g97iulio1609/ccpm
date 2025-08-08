import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppAccordion extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool showDivider;
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  const AppAccordion({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.initiallyExpanded = false,
    this.showDivider = true,
    this.contentPadding,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  State<AppAccordion> createState() => _AppAccordionState();
}

class _AppAccordionState extends State<AppAccordion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = _controller.drive(
      Tween<double>(
        begin: 0.0,
        end: 0.5,
      ).chain(CurveTween(curve: Curves.easeIn)),
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
    _isExpanded =
        PageStorage.of(context).readState(context) as bool? ??
        widget.initiallyExpanded;
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      PageStorage.of(context).writeState(context, _isExpanded);
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ??
            colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled ? _handleTap : null,
              borderRadius:
                  widget.borderRadius ??
                  BorderRadius.circular(AppTheme.radii.lg),
              child: Padding(
                padding:
                    widget.contentPadding ??
                    EdgeInsets.all(AppTheme.spacing.lg),
                child: Row(
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      SizedBox(width: AppTheme.spacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: widget.enabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant.withAlpha(128),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            SizedBox(height: AppTheme.spacing.xs),
                            Text(
                              widget.subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.enabled
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurfaceVariant.withAlpha(
                                        179,
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    widget.trailing ??
                        RotationTransition(
                          turns: _iconTurns,
                          child: Icon(
                            Icons.expand_more,
                            color: widget.enabled
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurfaceVariant.withAlpha(179),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          ClipRect(
            child: AnimatedBuilder(
              animation: _controller.view,
              builder: (BuildContext context, Widget? child) {
                return SizeTransition(sizeFactor: _heightFactor, child: child);
              },
              child: Column(
                children: [
                  if (widget.showDivider)
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withAlpha(26),
                    ),
                  Padding(
                    padding:
                        widget.contentPadding ??
                        EdgeInsets.all(AppTheme.spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.children,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget per gruppi di accordion
class AppAccordionGroup extends StatefulWidget {
  final List<AppAccordion> accordions;
  final bool allowMultiple;
  final EdgeInsets? padding;
  final double? spacing;

  const AppAccordionGroup({
    super.key,
    required this.accordions,
    this.allowMultiple = false,
    this.padding,
    this.spacing,
  });

  @override
  State<AppAccordionGroup> createState() => _AppAccordionGroupState();
}

class _AppAccordionGroupState extends State<AppAccordionGroup> {
  final Set<int> _expandedIndexes = {};

  void _handleAccordionTap(int index) {
    setState(() {
      if (_expandedIndexes.contains(index)) {
        _expandedIndexes.remove(index);
      } else {
        if (!widget.allowMultiple) {
          _expandedIndexes.clear();
        }
        _expandedIndexes.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < widget.accordions.length; i++) ...[
            AppAccordion(
              title: widget.accordions[i].title,
              subtitle: widget.accordions[i].subtitle,
              leading: widget.accordions[i].leading,
              initiallyExpanded: _expandedIndexes.contains(i),
              showDivider: widget.accordions[i].showDivider,
              contentPadding: widget.accordions[i].contentPadding,
              backgroundColor: widget.accordions[i].backgroundColor,
              borderRadius: widget.accordions[i].borderRadius,
              enabled: widget.accordions[i].enabled,
              onTap: () => _handleAccordionTap(i),
              trailing: widget.accordions[i].trailing,
              children: widget.accordions[i].children,
            ),
            if (i < widget.accordions.length - 1)
              SizedBox(height: widget.spacing ?? AppTheme.spacing.md),
          ],
        ],
      ),
    );
  }
}
