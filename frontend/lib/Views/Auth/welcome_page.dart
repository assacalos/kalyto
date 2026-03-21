import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/services/session_service.dart';

/// Page d'accueil avec branding produit neutre (Kalyto), boutons S'INSCRIRE et SE CONNECTER.
/// Aucun logo client : adapté à la revente à différentes entreprises.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _redirectChecked = false;

  @override
  Widget build(BuildContext context) {
    if (!_redirectChecked) {
      _redirectChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (await SessionService.isAuthenticated()) {
          context.go('/splash');
        }
      });
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond avec dégradé (couleur Kalyto)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF132642),
                  Color(0xFF0A1628),
                ],
              ),
            ),
          ),
          // Logo Kalyto (éléphant + barres + nom sur fond marbre)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Image.asset(
                'assets/images/welcome_logo.png',
                fit: BoxFit.contain,
                width: 320,
                errorBuilder: (_, __, ___) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business_center_rounded, size: 80, color: Colors.white.withOpacity(0.95)),
                    const SizedBox(height: 20),
                    Text('Kalyto', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Gestion d\'entreprise', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          // Overlay léger en bas pour la lisibilité des boutons
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
          // Boutons en haut à droite
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WelcomeButton(
                      label: "S'INSCRIRE",
                      onTap: () => context.go('/register'),
                    ),
                    const SizedBox(width: 12),
                    _WelcomeButton(
                      label: 'SE CONNECTER',
                      onTap: () => context.go('/login'),
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _WelcomeButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? Colors.white : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border:
                isPrimary
                    ? null
                    : Border.all(color: Colors.white54, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? const Color(0xFF0A1628) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
