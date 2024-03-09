import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Scrollable.of(context)!.position,
      builder: (context, child) {
        // Determina se l'app bar dovrebbe essere visibile
        final bool visible = Scrollable.of(context)!.position.userScrollDirection == ScrollDirection.forward;
        // Usa Tween per animare l'altezza dell'app bar
        final double topPadding = MediaQuery.of(context).padding.top;
        final double appBarHeight = visible ? kToolbarHeight + topPadding : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: appBarHeight,
          child: AppBar(
            title: Text(title),
            actions: actions,
            elevation: 0.0, // Puoi modificare l'elevazione qui
          ),
        );
      },
    );
  }

  @override
  // Fornisce un'altezza fissa quando l'app bar è visibile
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
