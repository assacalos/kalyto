import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/gen_l10n/app_localizations.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/validation_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easyconnect/Models/company_model.dart';
import 'package:easyconnect/services/company_service.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/providers/locale_provider.dart';

class AppSettingsPage extends ConsumerStatefulWidget {
  const AppSettingsPage({super.key});

  @override
  ConsumerState<AppSettingsPage> createState() => _AppSettingsPageState();
}

const String _kCompanyNineaKey = 'company_ninea';

class _AppSettingsPageState extends ConsumerState<AppSettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoBackup = false;
  late String _selectedLanguage;
  String _selectedTheme = 'system';
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _companyNineaController = TextEditingController();
  final _storage = GetStorage();
  List<Company> _companies = [];
  int? _selectedCompanyId;
  bool _companiesLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LocaleNotifier.getSavedLocaleCode();
    _apiUrlController.text = AppConfig.baseUrl;
    _companyNineaController.text = _storage.read<String>(_kCompanyNineaKey) ?? '';
    _selectedCompanyId = CompanyService.getCurrentCompanyId();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _companiesLoading = true);
    try {
      final list = await CompanyService.getCompanies();
      if (mounted) setState(() {
        _companies = list;
        _companiesLoading = false;
        if (_selectedCompanyId == null && list.isNotEmpty) {
          _selectedCompanyId = list.first.id;
          CompanyService.setCurrentCompanyId(_selectedCompanyId);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _companiesLoading = false);
    }
  }

  Future<void> _pickAndUploadLogo(BuildContext context) async {
    final companyId = _selectedCompanyId;
    if (companyId == null) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (xFile == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Envoi du logo...')));
    final result = await CompanyService.uploadCompanyLogo(companyId, xFile);
    if (!mounted) return;
    if (result['success'] == true) {
      await _loadCompanies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo enregistré.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Erreur lors de l\'envoi')),
      );
    }
  }

  Future<void> _pickAndUploadSignature(BuildContext context) async {
    final companyId = _selectedCompanyId;
    if (companyId == null) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (xFile == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Envoi de la signature...')));
    final result = await CompanyService.uploadCompanySignature(companyId, xFile);
    if (!mounted) return;
    if (result['success'] == true) {
      await _loadCompanies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature enregistrée.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Erreur lors de l\'envoi')),
      );
    }
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _companyNineaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(authProvider).user?.role == 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isAdmin) ...[
            _buildSectionHeader(l10n.currentCompany),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentCompanyHint,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    if (_companiesLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    else
                      DropdownButton<int>(
                        value: _selectedCompanyId,
                        isExpanded: true,
                        hint: Text(l10n.noCompanySelected),
                        items: [
                          DropdownMenuItem<int>(value: null, child: Text(l10n.allCompaniesMono, style: TextStyle(color: Colors.grey.shade600))),
                          ..._companies.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (int? id) async {
                          await CompanyService.setCurrentCompanyId(id);
                          if (mounted) setState(() => _selectedCompanyId = CompanyService.getCurrentCompanyId());
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeader(l10n.companyDataSection),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nineaLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyNineaController,
                      decoration: InputDecoration(
                        labelText: l10n.nineaField,
                        hintText: l10n.nineaHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.fingerprint),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 9,
                      onChanged: (_) => setState(() {}),
                      validator: (value) =>
                          ValidationHelper.validateNinea(value, required: false),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.nineaHelp,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedCompanyId != null) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('Logo et signature (PDF)'),
              Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ces images sont utilisées sur les devis, factures et bordereaux.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Logo (en-tête)'),
                            onPressed: () => _pickAndUploadLogo(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.draw),
                            label: const Text('Signature (pied de page)'),
                            onPressed: () => _pickAndUploadSignature(context),
                          ),
                        ),
                      ],
                    ),
                    if (_companies.any((c) => c.id == _selectedCompanyId && (c.logoUrl != null || c.signatureUrl != null)))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Logo et/ou signature configurés pour cette société.',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ],
          ],
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.apiConfigSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.apiUrl),
                  subtitle: Text(
                    AppConfig.getCurrentUrlInfo(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  leading: const Icon(Icons.api),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showApiUrlDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.resetApiUrl),
                  subtitle: Text(l10n.resetApiUrlSubtitle),
                  leading: const Icon(Icons.refresh),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showResetApiUrlDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionHeader(l10n.generalSection),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.notifications),
                  subtitle: Text(l10n.notificationsSubtitle),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.language),
                  subtitle: Text(_selectedLanguage == 'fr' ? l10n.languageFrench : l10n.languageEnglish),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.theme),
                  subtitle: Text(_getThemeName(_selectedTheme, l10n)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showThemeDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionHeader(l10n.testsSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.testPushNotifications),
                  subtitle: Text(l10n.testPushSubtitle),
                  leading: const Icon(
                    Icons.notifications_active,
                    color: Colors.blue,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go('/admin/push-test');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionHeader(l10n.securitySection),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.changePassword),
                  subtitle: Text(l10n.changePasswordSubtitle),
                  leading: const Icon(Icons.lock),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go('/admin/change-password');
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text(l10n.activeSessions),
                  subtitle: Text(l10n.activeSessionsSubtitle),
                  leading: const Icon(Icons.devices),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go('/admin/sessions');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Authentification à deux facteurs'),
                  subtitle: const Text('Sécuriser votre compte'),
                  leading: const Icon(Icons.security),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      // TODO: Implémenter 2FA
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Sauvegarde
          _buildSectionHeader('Sauvegarde et données'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sauvegarde automatique'),
                  subtitle: const Text(
                    'Sauvegarder automatiquement les données',
                  ),
                  value: _autoBackup,
                  onChanged: (value) {
                    setState(() {
                      _autoBackup = value;
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Sauvegarder maintenant'),
                  subtitle: const Text('Créer une sauvegarde manuelle'),
                  leading: const Icon(Icons.backup),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showBackupDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Restaurer depuis sauvegarde'),
                  subtitle: const Text('Restaurer les données'),
                  leading: const Icon(Icons.restore),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go('/admin/restore');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section Maintenance
          _buildSectionHeader('Maintenance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Nettoyer le cache'),
                  subtitle: const Text('Libérer l\'espace de stockage'),
                  leading: const Icon(Icons.cleaning_services),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showCacheDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Logs système'),
                  subtitle: const Text('Consulter les logs d\'erreur'),
                  leading: const Icon(Icons.article),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.go('/admin/logs');
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Informations système'),
                  subtitle: const Text('Version et détails techniques'),
                  leading: const Icon(Icons.info),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showSystemInfo();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bouton de sauvegarde
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _saveSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                l10n.saveSettings,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  String _getThemeName(String theme, AppLocalizations l10n) {
    switch (theme) {
      case 'light':
        return l10n.themeLight;
      case 'dark':
        return l10n.themeDark;
      case 'system':
      default:
        return l10n.themeSystem;
    }
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.languageFrench),
              value: 'fr',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                if (value == null) return;
                ref.read(localeProvider.notifier).setLocale(const Locale('fr'));
                setState(() => _selectedLanguage = 'fr');
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                if (value == null) return;
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                setState(() => _selectedLanguage = 'en');
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.themeLight),
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text(l10n.themeDark),
                  value: 'dark',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<String>(
                  title: Text(l10n.themeSystem),
                  value: 'system',
                  groupValue: _selectedTheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sauvegarder'),
            content: const Text(
              'Voulez-vous créer une sauvegarde maintenant ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sauvegarde créée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Sauvegarder'),
              ),
            ],
          ),
    );
  }

  void _showCacheDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nettoyer le cache'),
            content: const Text(
              'Cette action va supprimer tous les fichiers temporaires. Continuer ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache nettoyé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Nettoyer'),
              ),
            ],
          ),
    );
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Informations système'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version: 1.0.0'),
                Text('Build: 2024.01.15'),
                Text('Flutter: 3.16.0'),
                Text('Dart: 3.2.0'),
                Text('Plateforme: Android/iOS'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showApiUrlDialog() {
    _apiUrlController.text = AppConfig.baseUrl;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Configuration de l\'URL de l\'API'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _apiUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL de l\'API',
                    hintText: 'https://example.com/api',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'URL actuelle: ${AppConfig.baseUrl}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newUrl = _apiUrlController.text.trim();
                  if (newUrl.isNotEmpty) {
                    await AppConfig.setBaseUrl(newUrl);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL de l\'API mise à jour avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'URL ne peut pas être vide'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _showResetApiUrlDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Réinitialiser l\'URL de l\'API'),
            content: const Text(
              'Voulez-vous réinitialiser l\'URL de l\'API à sa valeur par défaut ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await AppConfig.resetBaseUrl();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('URL de l\'API réinitialisée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
    );
  }

  void _saveSettings() {
    final ninea = _companyNineaController.text.replaceAll(RegExp(r'\s'), '').trim();
    final nineaError = ValidationHelper.validateNinea(ninea, required: false);
    if (nineaError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nineaError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _storage.write(_kCompanyNineaKey, ninea.isEmpty ? null : ninea);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres sauvegardés avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
