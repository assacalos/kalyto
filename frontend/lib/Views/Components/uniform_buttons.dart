import 'package:flutter/material.dart';

/// Composant de bouton d'ajout uniforme pour Scaffold.floatingActionButton.
/// Ne pas utiliser Positioned : le Scaffold positionne déjà le FAB.
class UniformAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UniformAddButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Colors.green,
      foregroundColor: foregroundColor ?? Colors.white,
      icon: Icon(icon),
      label: Text(label),
      elevation: 4,
    );
  }
}

/// Composant de bouton d'ajout simple (sans positionnement)
class UniformAddButtonSimple extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UniformAddButtonSimple({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.green,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Composant de boutons d'action uniformes pour les formulaires
class UniformFormButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String cancelText;
  final String submitText;
  final bool isLoading;
  final Color? submitButtonColor;
  final Color? cancelButtonColor;

  const UniformFormButtons({
    Key? key,
    required this.onCancel,
    required this.onSubmit,
    this.cancelText = 'Annuler',
    this.submitText = 'Soumettre',
    this.isLoading = false,
    this.submitButtonColor,
    this.cancelButtonColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: cancelButtonColor ?? Colors.grey.shade700,
                side: BorderSide(
                  color: cancelButtonColor ?? Colors.grey.shade400,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                cancelText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: submitButtonColor ?? Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        submitText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Composant de bouton d'ajout pour les sections (avec icône +)
class UniformSectionAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UniformSectionAddButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Colors.green,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 1,
      ),
    );
  }
}

/// Composant de bouton d'action flottant pour les pages de liste
class UniformFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UniformFloatingActionButton({
    Key? key,
    required this.onPressed,
    required this.tooltip,
    this.icon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? Colors.green,
      foregroundColor: foregroundColor ?? Colors.white,
      child: Icon(icon),
    );
  }
}
