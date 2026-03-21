import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Sur le web : utilise toute la largeur utile (max 1600px pour lisibilité sur grand écran).
/// Plus de bande étroite type mobile — affichage adapté au bureau.
class ResponsiveWebWrapper extends StatelessWidget {
  const ResponsiveWebWrapper({super.key, required this.child});

  final Widget child;

  /// Largeur max du contenu sur web (évite lignes trop longues sur très grands écrans)
  static const double kWebMaxContentWidth = 1600.0;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final contentWidth = width > kWebMaxContentWidth ? kWebMaxContentWidth : width;

    return Center(
      child: SizedBox(
        width: contentWidth,
        height: height,
        child: child,
      ),
    );
  }
}
