import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/Main/app_theme.dart';

typedef SuggestionsCallback<T> = Future<List<T>> Function(String pattern);
typedef ItemBuilder<T> = Widget Function(BuildContext context, T suggestion);
typedef FieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
);
typedef OverlayDecorator = Widget Function(BuildContext context, Widget child);

class AppAutocompleteField<T> extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FieldBuilder builder;
  final SuggestionsCallback<T> suggestionsCallback;
  final ItemBuilder<T> itemBuilder;
  final ValueChanged<T> onSelected;
  final Duration debounceDuration;
  final bool hideOnEmpty;
  final bool hideOnLoading;
  final bool hideOnError;
  final BoxConstraints? constraints;
  final OverlayDecorator? decorationBuilder;
  final Widget Function(BuildContext)? emptyBuilder;
  final Offset offset;
  final Duration animationDuration;

  const AppAutocompleteField({
    super.key,
    this.controller,
    this.focusNode,
    required this.builder,
    required this.suggestionsCallback,
    required this.itemBuilder,
    required this.onSelected,
    this.debounceDuration = const Duration(milliseconds: 250),
    this.hideOnEmpty = true,
    this.hideOnLoading = false,
    this.hideOnError = false,
    this.constraints,
    this.decorationBuilder,
    this.emptyBuilder,
    this.offset = Offset.zero,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AppAutocompleteField<T>> createState() => _AppAutocompleteFieldState<T>();
}

class _AppAutocompleteFieldState<T> extends State<AppAutocompleteField<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final LayerLink _layerLink;
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<T> _options = const [];
  // Keep minimal state; last query not needed currently
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _layerLink = LayerLink();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_handleFocusChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    } else {
      _maybeShowOverlay();
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () async {
      if (!mounted) return;
      _fetchOptions(query);
    });
  }

  Future<void> _fetchOptions(String query) async {
      if (query.isEmpty) {
      setState(() {
        _options = const [];
        _loading = false;
        _error = false;
      });
      _maybeShowOverlay();
      return;
    }
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await widget.suggestionsCallback(query);
      if (!mounted) return;
      setState(() {
        _options = result;
        _loading = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _options = const [];
        _loading = false;
        _error = true;
      });
    }
    _maybeShowOverlay();
  }

  void _maybeShowOverlay() {
    final shouldHide =
        (!mounted) || !_focusNode.hasFocus ||
        (widget.hideOnLoading && _loading) ||
        (widget.hideOnError && _error) ||
        (widget.hideOnEmpty && !_loading && !_error && _options.isEmpty);

    if (shouldHide) {
      _removeOverlay();
      return;
    }
    _insertOrUpdateOverlay();
  }

  void _insertOrUpdateOverlay() {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
      Overlay.of(context, debugRequiredFor: widget).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    final overlayChild = CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: widget.offset,
      child: ConstrainedBox(
        constraints: widget.constraints ?? const BoxConstraints(maxHeight: 260, minWidth: 280),
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: widget.animationDuration,
          child: GlassLite(
            radius: AppTheme.radii.lg,
            blur: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              child: _buildOptionsList(),
            ),
          ),
        ),
      ),
    );
    if (widget.decorationBuilder != null) {
      return widget.decorationBuilder!(context, overlayChild);
    }
    return overlayChild;
  }

  Widget _buildOptionsList() {
    final cs = Theme.of(context).colorScheme;
    if (_loading && !widget.hideOnLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error && !widget.hideOnError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Errore nel caricamento', style: TextStyle(color: cs.error)),
      );
    }
    if (_options.isEmpty) {
      if (widget.emptyBuilder != null && !widget.hideOnEmpty) {
        return widget.emptyBuilder!(context);
      }
      return const SizedBox.shrink();
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _options.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: cs.outline.withAlpha(26),
      ),
      itemBuilder: (context, index) {
        final item = _options[index];
        return InkWell(
          onTap: () {
            widget.onSelected(item);
            _removeOverlay();
          },
          hoverColor: cs.primary.withAlpha(24),
          splashColor: cs.primary.withAlpha(48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.md,
              vertical: AppTheme.spacing.sm,
            ),
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
              child: widget.itemBuilder(context, item),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.builder(context, _controller, _focusNode),
    );
  }
}
