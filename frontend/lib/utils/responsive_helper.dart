import 'package:flutter/material.dart';

/// Helper pour gérer le responsive design de manière centralisée
class ResponsiveHelper {
  /// Retourne la largeur de l'écran
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Retourne la hauteur de l'écran
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Retourne la taille de l'écran
  static Size screenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Retourne le padding de l'écran (safe area)
  static EdgeInsets screenPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Vérifie si l'écran est petit (mobile)
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  /// Vérifie si l'écran est moyen (tablette)
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 1200;
  }

  /// Vérifie si l'écran est grand (desktop)
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1200;
  }

  /// Retourne le nombre de colonnes selon la taille d'écran
  static int getColumnCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Retourne le padding horizontal selon la taille d'écran
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Retourne le padding vertical selon la taille d'écran
  static double getVerticalPadding(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  /// Retourne la taille de police selon la taille d'écran
  static double getFontSize(
    BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne la taille d'icône selon la taille d'écran
  static double getIconSize(
    BuildContext context, {
    double mobile = 24.0,
    double tablet = 28.0,
    double desktop = 32.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne l'espacement selon la taille d'écran
  static double getSpacing(
    BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne la largeur maximale pour le contenu
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800.0;
    return 1200.0;
  }

  /// Retourne le nombre d'éléments par ligne dans une grille
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// Retourne le childAspectRatio pour les grilles
  static double getGridChildAspectRatio(BuildContext context) {
    if (isMobile(context)) return 1.1;
    if (isTablet(context)) return 1.2;
    return 1.3;
  }
}
