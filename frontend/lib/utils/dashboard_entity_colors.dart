import 'package:flutter/material.dart';

/// Palette de couleurs par entité pour les dashboards.
/// Chaque entité a une couleur distinctive (icône, badge, bordure).
class DashboardEntityColors {
  DashboardEntityColors._();

  // ——— Commercial
  static const Color clients = Color(0xFF3B82F6);       // Bleu
  static const Color devis = Color(0xFF10B981);        // Vert émeraude
  static const Color bordereaux = Color(0xFFF59E0B);   // Ambre
  static const Color bonCommandes = Color(0xFF8B5CF6);  // Violet
  static const Color bonCommandesFournisseur = Color(0xFF6366F1); // Indigo
  static const Color tasks = Color(0xFF7C3AED);        // Violet foncé

  // ——— Patron / Validations
  static const Color inscriptions = Color(0xFFEA580C); // Orange
  static const Color factures = Color(0xFFDC2626);    // Rouge
  static const Color pointages = Color(0xFF78716C);   // Stone
  static const Color paiements = Color(0xFF0D9488);   // Teal
  static const Color depenses = Color(0xFFA855F7);    // Violet clair
  static const Color salaires = Color(0xFFEAB308);    // Jaune
  static const Color reporting = Color(0xFF6366F1);   // Indigo
  static const Color employes = Color(0xFF06B6D4);    // Cyan

  // ——— Comptable
  static const Color expenses = Color(0xFFEA580C);     // Orange (dépenses)
  static const Color salaries = Color(0xFF7C3AED);    // Violet (salaires)
  static const Color taxes = Color(0xFF0D9488);       // Teal
  static const Color stock = Color(0xFF059669);        // Vert
  static const Color inventaire = Color(0xFF0E7490);   // Cyan foncé
  static const Color fournisseurs = Color(0xFFF59E0B); // Ambre

  // ——— RH
  static const Color conges = Color(0xFF0EA5E9);      // Sky
  static const Color recruitment = Color(0xFF10B981); // Vert
  static const Color contracts = Color(0xFF7C3AED);    // Violet
  static const Color attendance = Color(0xFFF59E0B);  // Ambre

  // ——— Technicien
  static const Color interventions = Color(0xFFEA580C); // Orange
  static const Color besoins = Color(0xFF0D9488);       // Teal
  static const Color equipments = Color(0xFF7C3AED);     // Violet

  // ——— Commun
  static const Color finances = Color(0xFF059669);
  static const Color journal = Color(0xFF64748B);
  static const Color grandLivre = Color(0xFF0F766E);
  static const Color balance = Color(0xFF0369A1);
  static const Color rapports = Color(0xFF6366F1);
  static const Color parametres = Color(0xFF64748B);
}
