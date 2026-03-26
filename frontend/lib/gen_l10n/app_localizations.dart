import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Kalyto'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Votre solution ERP intégrée'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un email valide'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordMinLength;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @welcomeUser.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue {name} !'**
  String welcomeUser(String name);

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @export.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get export;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre'**
  String get submit;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @reject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get reject;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de l\'application'**
  String get settingsTitle;

  /// No description provided for @currentCompany.
  ///
  /// In fr, this message translates to:
  /// **'Société courante'**
  String get currentCompany;

  /// No description provided for @currentCompanyHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la société pour les données affichées (clients, factures, journal, etc.)'**
  String get currentCompanyHint;

  /// No description provided for @noCompanySelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune société sélectionnée'**
  String get noCompanySelected;

  /// No description provided for @allCompaniesMono.
  ///
  /// In fr, this message translates to:
  /// **'Toutes (mode mono-société)'**
  String get allCompaniesMono;

  /// No description provided for @companyUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Société mise à jour'**
  String get companyUpdated;

  /// No description provided for @companyAll.
  ///
  /// In fr, this message translates to:
  /// **'Société : toutes'**
  String get companyAll;

  /// No description provided for @companyDataSection.
  ///
  /// In fr, this message translates to:
  /// **'Données société / Entreprise'**
  String get companyDataSection;

  /// No description provided for @nineaLabel.
  ///
  /// In fr, this message translates to:
  /// **'NINEA (numéro d\'identification ivoirien de l\'entreprise)'**
  String get nineaLabel;

  /// No description provided for @nineaField.
  ///
  /// In fr, this message translates to:
  /// **'NINEA entreprise'**
  String get nineaField;

  /// No description provided for @nineaHint.
  ///
  /// In fr, this message translates to:
  /// **'9 chiffres'**
  String get nineaHint;

  /// No description provided for @nineaHelp.
  ///
  /// In fr, this message translates to:
  /// **'Exactement 9 chiffres. Enregistré localement jusqu\'à liaison avec l\'API.'**
  String get nineaHelp;

  /// No description provided for @apiConfigSection.
  ///
  /// In fr, this message translates to:
  /// **'Configuration API'**
  String get apiConfigSection;

  /// No description provided for @apiUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL de l\'API'**
  String get apiUrl;

  /// No description provided for @resetApiUrl.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser l\'URL'**
  String get resetApiUrl;

  /// No description provided for @resetApiUrlSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer l\'URL par défaut'**
  String get resetApiUrlSubtitle;

  /// No description provided for @generalSection.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get generalSection;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des notifications push'**
  String get notificationsSubtitle;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner la langue'**
  String get selectLanguage;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @selectTheme.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner le thème'**
  String get selectTheme;

  /// No description provided for @testsSection.
  ///
  /// In fr, this message translates to:
  /// **'Tests et développement'**
  String get testsSection;

  /// No description provided for @testPushNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Test Notifications Push'**
  String get testPushNotifications;

  /// No description provided for @testPushSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tester la configuration Firebase et FCM'**
  String get testPushSubtitle;

  /// No description provided for @securitySection.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securitySection;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier votre mot de passe'**
  String get changePasswordSubtitle;

  /// No description provided for @activeSessions.
  ///
  /// In fr, this message translates to:
  /// **'Sessions actives'**
  String get activeSessions;

  /// No description provided for @activeSessionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les sessions ouvertes'**
  String get activeSessionsSubtitle;

  /// No description provided for @menuInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get menuInvoices;

  /// No description provided for @menuPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get menuPayments;

  /// No description provided for @menuExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get menuExpenses;

  /// No description provided for @menuSalaries.
  ///
  /// In fr, this message translates to:
  /// **'Salaires'**
  String get menuSalaries;

  /// No description provided for @menuJournal.
  ///
  /// In fr, this message translates to:
  /// **'Journal des comptes'**
  String get menuJournal;

  /// No description provided for @menuGrandLivre.
  ///
  /// In fr, this message translates to:
  /// **'Grand livre'**
  String get menuGrandLivre;

  /// No description provided for @menuBalance.
  ///
  /// In fr, this message translates to:
  /// **'Balance'**
  String get menuBalance;

  /// No description provided for @menuTaxes.
  ///
  /// In fr, this message translates to:
  /// **'Impôts et Taxes'**
  String get menuTaxes;

  /// No description provided for @menuStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get menuStock;

  /// No description provided for @menuInventory.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire physique'**
  String get menuInventory;

  /// No description provided for @menuSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs'**
  String get menuSuppliers;

  /// No description provided for @menuAttendance.
  ///
  /// In fr, this message translates to:
  /// **'Pointage'**
  String get menuAttendance;

  /// No description provided for @menuMyTasks.
  ///
  /// In fr, this message translates to:
  /// **'Mes tâches'**
  String get menuMyTasks;

  /// No description provided for @roleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rôle: {role}'**
  String roleLabel(String role);

  /// No description provided for @dashboardComptable.
  ///
  /// In fr, this message translates to:
  /// **'Comptable'**
  String get dashboardComptable;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @saveSettings.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder les paramètres'**
  String get saveSettings;

  /// No description provided for @allCompaniesMonoShort.
  ///
  /// In fr, this message translates to:
  /// **'Toutes (mono-société)'**
  String get allCompaniesMonoShort;

  /// No description provided for @dashboardLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le dashboard.'**
  String get dashboardLoadError;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
