// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Kalyto';

  @override
  String get appTagline => 'Votre solution ERP intégrée';

  @override
  String get login => 'Se connecter';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Entrez votre email';

  @override
  String get emailRequired => 'Veuillez entrer votre email';

  @override
  String get emailInvalid => 'Veuillez entrer un email valide';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHint => 'Entrez votre mot de passe';

  @override
  String get passwordRequired => 'Veuillez entrer votre mot de passe';

  @override
  String get passwordMinLength => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String welcomeUser(String name) {
    return 'Bienvenue $name !';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get refresh => 'Actualiser';

  @override
  String get export => 'Exporter';

  @override
  String get search => 'Rechercher';

  @override
  String get close => 'Fermer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get submit => 'Soumettre';

  @override
  String get validate => 'Valider';

  @override
  String get reject => 'Rejeter';

  @override
  String get settings => 'Paramètres';

  @override
  String get settingsTitle => 'Paramètres de l\'application';

  @override
  String get currentCompany => 'Société courante';

  @override
  String get currentCompanyHint => 'Choisir la société pour les données affichées (clients, factures, journal, etc.)';

  @override
  String get noCompanySelected => 'Aucune société sélectionnée';

  @override
  String get allCompaniesMono => 'Toutes (mode mono-société)';

  @override
  String get companyUpdated => 'Société mise à jour';

  @override
  String get companyAll => 'Société : toutes';

  @override
  String get companyDataSection => 'Données société / Entreprise';

  @override
  String get nineaLabel => 'NINEA (numéro d\'identification ivoirien de l\'entreprise)';

  @override
  String get nineaField => 'NINEA entreprise';

  @override
  String get nineaHint => '9 chiffres';

  @override
  String get nineaHelp => 'Exactement 9 chiffres. Enregistré localement jusqu\'à liaison avec l\'API.';

  @override
  String get apiConfigSection => 'Configuration API';

  @override
  String get apiUrl => 'URL de l\'API';

  @override
  String get resetApiUrl => 'Réinitialiser l\'URL';

  @override
  String get resetApiUrlSubtitle => 'Restaurer l\'URL par défaut';

  @override
  String get generalSection => 'Général';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Recevoir des notifications push';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get selectTheme => 'Sélectionner le thème';

  @override
  String get testsSection => 'Tests et développement';

  @override
  String get testPushNotifications => 'Test Notifications Push';

  @override
  String get testPushSubtitle => 'Tester la configuration Firebase et FCM';

  @override
  String get securitySection => 'Sécurité';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordSubtitle => 'Modifier votre mot de passe';

  @override
  String get activeSessions => 'Sessions actives';

  @override
  String get activeSessionsSubtitle => 'Gérer les sessions ouvertes';

  @override
  String get menuInvoices => 'Factures';

  @override
  String get menuPayments => 'Paiements';

  @override
  String get menuExpenses => 'Dépenses';

  @override
  String get menuSalaries => 'Salaires';

  @override
  String get menuJournal => 'Journal des comptes';

  @override
  String get menuGrandLivre => 'Grand livre';

  @override
  String get menuBalance => 'Balance';

  @override
  String get menuTaxes => 'Impôts et Taxes';

  @override
  String get menuStock => 'Stock';

  @override
  String get menuInventory => 'Inventaire physique';

  @override
  String get menuSuppliers => 'Fournisseurs';

  @override
  String get menuAttendance => 'Pointage';

  @override
  String get menuMyTasks => 'Mes tâches';

  @override
  String roleLabel(String role) {
    return 'Rôle: $role';
  }

  @override
  String get dashboardComptable => 'Comptable';

  @override
  String get home => 'Accueil';

  @override
  String get profile => 'Profil';

  @override
  String get saveSettings => 'Sauvegarder les paramètres';

  @override
  String get allCompaniesMonoShort => 'Toutes (mono-société)';

  @override
  String get dashboardLoadError => 'Impossible de charger le dashboard.';

  @override
  String get retry => 'Réessayer';
}
