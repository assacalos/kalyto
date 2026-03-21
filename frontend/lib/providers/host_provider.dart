import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index de l'onglet actif dans la barre de navigation du Host.
final hostIndexProvider = StateProvider<int>((ref) => 0);
