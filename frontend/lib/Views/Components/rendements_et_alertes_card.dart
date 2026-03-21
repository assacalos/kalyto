import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Une entrée "rendement" : libellé + valeur + route optionnelle au tap.
class RendementItem {
  final String label;
  final String value;
  final String? route;
  final IconData? icon;
  final Color? color;

  const RendementItem({
    required this.label,
    required this.value,
    this.route,
    this.icon,
    this.color,
  });
}

/// Une alerte / rappel : message + route optionnelle.
class AlerteItem {
  final String message;
  final String? route;
  final IconData icon;
  final Color color;

  const AlerteItem({
    required this.message,
    this.route,
    this.icon = Icons.warning_amber_rounded,
    this.color = const Color(0xFFDC2626),
  });
}

/// Carte "Mes rendements" + "Ce qui ne va pas / À faire" pour inciter chaque rôle à voir son travail et les points à traiter.
class RendementsEtAlertesCard extends StatelessWidget {
  final String titleRendements;
  final List<RendementItem> rendements;
  final String titleAlertes;
  final List<AlerteItem> alertes;

  const RendementsEtAlertesCard({
    super.key,
    this.titleRendements = 'Mes rendements',
    required this.rendements,
    this.titleAlertes = 'À faire / Ce qui ne va pas',
    required this.alertes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rendements.isNotEmpty) ...[
          Text(
            titleRendements.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ...rendements.map((r) => _buildRendementRow(context, r)),
          const SizedBox(height: 16),
        ],
        if (alertes.isNotEmpty) ...[
          Text(
            titleAlertes.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ...alertes.map((a) => _buildAlerteRow(context, a)),
        ],
      ],
    );
  }

  Widget _buildRendementRow(BuildContext context, RendementItem r) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          if (r.icon != null) ...[
            Icon(r.icon, size: 20, color: r.color ?? const Color(0xFF059669)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              r.label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
          Text(
            r.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: r.color ?? const Color(0xFF059669),
            ),
          ),
          if (r.route != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade500),
          ],
        ],
      ),
    );
    if (r.route != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.go(r.route!),
            borderRadius: BorderRadius.circular(12),
            child: content,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            if (r.icon != null) ...[
              Icon(r.icon, size: 20, color: r.color ?? const Color(0xFF059669)),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(r.label, style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
            Text(r.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: r.color ?? const Color(0xFF059669))),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerteRow(BuildContext context, AlerteItem a) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          Icon(a.icon, size: 20, color: a.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              a.message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
          if (a.route != null)
            Icon(Icons.arrow_forward_ios, size: 12, color: a.color),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: a.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: a.route != null ? () => context.go(a.route!) : null,
          borderRadius: BorderRadius.circular(12),
          child: content,
        ),
      ),
    );
  }
}
