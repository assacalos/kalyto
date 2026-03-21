import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bouton retour pour l'AppBar : pop si possible, sinon [context.go] vers [fallbackRoute].
/// À utiliser en [AppBar.leading] pour que le retour soit toujours visible (surtout avec GoRouter qui utilise [go]).
class AppBarBackButton extends StatelessWidget {
  final String? fallbackRoute;
  final Color? iconColor;

  const AppBarBackButton({
    super.key,
    this.fallbackRoute,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      color: color,
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          context.pop();
        } else if (fallbackRoute != null && fallbackRoute!.isNotEmpty) {
          context.go(fallbackRoute!);
        }
      },
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
