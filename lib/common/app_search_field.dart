import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';

typedef SuggestionsCallback<T> = Future<List<T>> Function(String pattern);
typedef ItemBuilder<T> = Widget Function(BuildContext context, T suggestion);

/// AppSearchField
///
/// Unified SearchAnchor + SearchBar autocomplete with debounced async suggestions
/// and glassmorphism overlay following the “Glass lite” spec.
class AppSearchField<T> extends HookConsumerWidget {
  final TextEditingController controller;
  final String hintText;
  final SuggestionsCallback<T> suggestionsCallback;
  final ItemBuilder<T> itemBuilder;
  final ValueChanged<T> onSelected;
  final ValueChanged<String>? onChanged;
  final Widget? emptyBuilder;
  final IconData? prefixIcon;
  final bool isFullScreen;
  final Duration debounceDuration;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.suggestionsCallback,
    required this.itemBuilder,
    required this.onSelected,
    this.onChanged,
    this.emptyBuilder,
    this.prefixIcon,
    this.isFullScreen = false,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final searchController = useMemoized(() => SearchController());
    // Sync initial value
    useEffect(() {
      searchController.text = controller.text;
      return null;
    }, const []);
    final results = useState<List<T>>(<T>[]);
    final loading = useState<bool>(false);
    final error = useState<bool>(false);
    final timer = useRef<Timer?>(null);
    final lastReqId = useRef<int>(0);

    void fetch(String query) async {
      timer.value?.cancel();
      timer.value = Timer(debounceDuration, () async {
        final int req = ++lastReqId.value;
        try {
          if (query.isEmpty) {
            results.value = <T>[];
            loading.value = false;
            error.value = false;
            return;
          }
          loading.value = true;
          error.value = false;
          final data = await suggestionsCallback(query);
          if (req == lastReqId.value) {
            results.value = data;
            loading.value = false;
          }
        } catch (_) {
          if (req == lastReqId.value) {
            loading.value = false;
            error.value = true;
            results.value = <T>[];
          }
        }
      });
    }

    useEffect(() {
      void listener() {
        // Keep SearchController text in sync if external controller changes
        if (controller.text != searchController.text) {
          searchController.text = controller.text;
        }
      }

      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    final glassEnabled = ref.watch(uiGlassEnabledProvider);
    // React to SearchController text changes (works for both bar and overlay input).
    useEffect(() {
      void scListener() {
        final value = searchController.text;
        onChanged?.call(value);
        fetch(value);
      }

      searchController.addListener(scListener);
      return () => searchController.removeListener(scListener);
    }, [searchController]);

    return Theme(
      data: Theme.of(context).copyWith(
        // Apply glass-like overlay for the search view
        searchViewTheme: SearchViewThemeData(
          backgroundColor: glassEnabled ? cs.surfaceContainerHighest.withAlpha(184) : cs.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            side: BorderSide(color: cs.outline.withAlpha(90)),
          ),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: SearchAnchor(
        searchController: searchController,
        isFullScreen: isFullScreen,
        builder: (context, controllerAnchor) {
          return SearchBar(
            controller: searchController,
            hintText: hintText,
            leading: Icon(prefixIcon ?? Icons.search, color: cs.primary),
            onTap: searchController.openView,
            onChanged: (value) {
              // Keep external controller in sync and fetch suggestions
              controller.text = value;
              onChanged?.call(value);
              searchController.openView();
              fetch(value);
            },
            onSubmitted: (value) {
              controller.text = value;
              onChanged?.call(value);
            },
            padding: MaterialStatePropertyAll(EdgeInsets.all(AppTheme.spacing.md)),
            elevation: const MaterialStatePropertyAll(0),
            backgroundColor: MaterialStatePropertyAll(cs.surfaceContainerHighest.withAlpha(184)),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                side: BorderSide(color: cs.outline.withAlpha(90)),
              ),
            ),
          );
        },
        suggestionsBuilder: (context, controllerAnchor) {
          final List<Widget> widgets = <Widget>[];
          if (loading.value) {
            widgets.add(
              Container(
                color: cs.surface.withAlpha(196),
                child: const ListTile(
                  leading: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text('Caricamento...'),
                ),
              ),
            );
            return widgets;
          }
          if (error.value) {
            widgets.add(
              Container(
                color: cs.surface.withAlpha(196),
                child: ListTile(
                  leading: Icon(Icons.error_outline, color: cs.error),
                  title: Text('Errore nel caricamento', style: TextStyle(color: cs.error)),
                ),
              ),
            );
            return widgets;
          }
          if (results.value.isEmpty) {
            if (emptyBuilder != null) {
              widgets.add(
                Container(
                  color: cs.surface.withAlpha(196),
                  child: ListTile(
                    title: DefaultTextStyle.merge(
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      child: emptyBuilder!,
                    ),
                  ),
                ),
              );
            }
            return widgets;
          }
          return results.value.map((e) {
            return Container(
              decoration: BoxDecoration(color: cs.surface.withAlpha(196)),
              child: InkWell(
                onTap: () {
                  onSelected(e);
                  // Close the view; callers manage the external controller text.
                  controllerAnchor.closeView(searchController.text);
                },
                child: itemBuilder(context, e),
              ),
            );
          });
        },
      ),
    );
  }
}
