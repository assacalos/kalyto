import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/devis_notifier.dart';
import 'package:easyconnect/providers/devis_state.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/responsive_widgets.dart';
import 'package:easyconnect/utils/responsive_helper.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:easyconnect/utils/tva_rates_ci.dart';
import 'package:easyconnect/utils/app_config.dart';

class DevisListPage extends ConsumerStatefulWidget {
  final int? clientId;

  const DevisListPage({super.key, this.clientId});

  @override
  ConsumerState<DevisListPage> createState() => _DevisListPageState();
}

class _DevisListPageState extends ConsumerState<DevisListPage>
    with SingleTickerProviderStateMixin {
  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA ');
  final formatDate = DateFormat('dd/MM/yyyy');
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  static const List<int> _statusByTabIndex = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(devisProvider.notifier).loadDevis(
        status: _statusByTabIndex[_tabController.index],
        forceRefresh: true,
      );
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final status = _statusByTabIndex[_tabController.index];
    ref.read(devisProvider.notifier).loadDevis(status: status, forceRefresh: true);
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(AppConfig.realtimeListRefreshInterval, (_) {
      if (!mounted) return;
      final status = _statusByTabIndex[_tabController.index];
      ref.read(devisProvider.notifier).loadDevis(status: status, forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final devisState = ref.watch(devisProvider);
    final notifier = ref.read(devisProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/devis'),
        title: const Text('Devis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadDevis(
              status: _statusByTabIndex[_tabController.index],
              forceRefresh: true,
            ),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Validés'),
            Tab(text: 'Rejetés'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildDevisList(context, 1, devisState, notifier),
              _buildDevisList(context, 2, devisState, notifier),
              _buildDevisList(context, 3, devisState, notifier),
            ],
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: UniformAddButton(
              onPressed: () => context.go('/devis/new'),
              label: 'Nouveau Devis',
              icon: Icons.description,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevisList(BuildContext context, int status, DevisState devisState, DevisNotifier notifier) {
    if (devisState.isLoading) {
      return const SkeletonSearchResults(itemCount: 6);
    }

    var devisList = devisState.devis.where((d) => d.status == status).toList();
    final filterClientId = widget.clientId;
    if (filterClientId != null) {
      devisList = devisList.where((d) => d.clientId == filterClientId).toList();
    }

    if (devisList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 1 ? Icons.access_time : status == 2 ? Icons.check_circle : Icons.cancel,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              status == 1 ? 'Aucun devis en attente' : status == 2 ? 'Aucun devis validé' : 'Aucun devis rejeté',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ResponsiveScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getHorizontalPadding(context),
        vertical: ResponsiveHelper.getVerticalPadding(context),
      ),
      child: Column(
        children: devisList.map((devis) {
          return ResponsiveCard(
            padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
            elevation: 2.0,
            child: _buildDevisCard(context, devis, status, notifier),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDevisCard(BuildContext context, Devis devis, int status, DevisNotifier notifier) {
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getSpacing(
          context,
          mobile: 4.0,
          tablet: 6.0,
          desktop: 8.0,
        ),
      ),
      elevation: 2.0,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: devis.statusColor.withOpacity(0.1),
          child: Icon(
            devis.statusIcon,
            color: devis.statusColor,
            size: ResponsiveHelper.getIconSize(
              context,
              mobile: 20.0,
              tablet: 24.0,
              desktop: 28.0,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nom de l'entreprise en grand pour reconnaissance rapide
            ResponsiveText(
              devis.clientNomEntreprise?.isNotEmpty == true
                  ? devis.clientNomEntreprise!
                  : 'Client #${devis.clientId}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getFontSize(
                  context,
                  mobile: 17.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                color: Colors.grey.shade900,
              ),
            ),
            ResponsiveSpacing(height: 4),
            Row(
              children: [
                Expanded(
                  child: ResponsiveText(
                    devis.reference,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 13.0,
                        tablet: 14.0,
                        desktop: 15.0,
                      ),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                ResponsiveSpacing(width: 8),
                Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getSpacing(
                  context,
                  mobile: 6.0,
                  tablet: 8.0,
                  desktop: 10.0,
                ),
                vertical: ResponsiveHelper.getSpacing(
                  context,
                  mobile: 3.0,
                  tablet: 4.0,
                  desktop: 5.0,
                ),
              ),
              decoration: BoxDecoration(
                color: devis.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: devis.statusColor.withOpacity(0.5)),
              ),
              child: ResponsiveText(
                devis.statusText,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(
                    context,
                    mobile: 11.0,
                    tablet: 12.0,
                    desktop: 13.0,
                  ),
                  color: devis.statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(
            top: ResponsiveHelper.getSpacing(
              context,
              mobile: 4.0,
              tablet: 6.0,
              desktop: 8.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: ResponsiveHelper.getSpacing(context),
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: ResponsiveHelper.getIconSize(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                        color: Colors.grey.shade600,
                      ),
                      ResponsiveSpacing(width: 4),
                      ResponsiveText(
                        'Créé le ${formatDate.format(devis.dateCreation)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: ResponsiveHelper.getFontSize(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (devis.dateValidite != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event,
                          size: ResponsiveHelper.getIconSize(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          ),
                          color: Colors.grey.shade600,
                        ),
                        ResponsiveSpacing(width: 4),
                        Flexible(
                          child: ResponsiveText(
                            'Valide jusqu\'au ${formatDate.format(devis.dateValidite!)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: ResponsiveHelper.getFontSize(
                                context,
                                mobile: 11.0,
                                tablet: 12.0,
                                desktop: 13.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: ResponsiveHelper.getIconSize(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        ),
                        color: Colors.grey.shade600,
                      ),
                      ResponsiveSpacing(width: 4),
                      ResponsiveText(
                        '${devis.items.length} article${devis.items.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: ResponsiveHelper.getFontSize(
                            context,
                            mobile: 11.0,
                            tablet: 12.0,
                            desktop: 13.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ResponsiveSpacing(height: 8),
              // Montant total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ResponsiveText(
                    'Total TTC:',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ResponsiveText(
                    formatCurrency.format(devis.totalTTC),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              // Commentaire de rejet si présent
              if (status == 3 &&
                  devis.rejectionComment != null &&
                  devis.rejectionComment!.isNotEmpty) ...[
                ResponsiveSpacing(height: 8),
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getSpacing(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.report,
                        color: Colors.red,
                        size: ResponsiveHelper.getIconSize(
                          context,
                          mobile: 16.0,
                          tablet: 18.0,
                          desktop: 20.0,
                        ),
                      ),
                      ResponsiveSpacing(width: 8),
                      Expanded(
                        child: ResponsiveText(
                          'Raison du rejet: ${devis.rejectionComment}',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: ResponsiveHelper.getFontSize(
                              context,
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.visibility,
            size: ResponsiveHelper.getIconSize(context),
          ),
          onPressed: () => context.go('/devis/${devis.id}'),
          tooltip: 'Voir les détails',
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(
              ResponsiveHelper.getSpacing(
                context,
                mobile: 12.0,
                tablet: 16.0,
                desktop: 20.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Détails des montants
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getSpacing(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildAmountRow(
                        'Sous-total HT:',
                        formatCurrency.format(devis.sousTotal),
                        context,
                      ),
                      if (devis.remiseGlobale != null &&
                          devis.remiseGlobale! > 0)
                        _buildAmountRow(
                          'Remise (${devis.remiseGlobale}%):',
                          '-${formatCurrency.format(devis.remise)}',
                          context,
                        ),
                      _buildAmountRow(
                        'Total HT:',
                        formatCurrency.format(devis.totalHT),
                        context,
                      ),
                      if (devis.tva != null && devis.tva! > 0)
                        _buildAmountRow(
                          '${tvaRateLabelCi(devis.tva!)}:',
                          formatCurrency.format(devis.montantTVA),
                          context,
                        ),
                      const Divider(),
                      _buildAmountRow(
                        'Total TTC:',
                        formatCurrency.format(devis.totalTTC),
                        context,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                ResponsiveSpacing(height: 16),
                // Liste des articles
                if (devis.items.isNotEmpty) ...[
                  ResponsiveText(
                    'Articles (${devis.items.length}):',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveSpacing(height: 8),
                  ...devis.items
                      .take(5)
                      .map(
                        (item) => Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getSpacing(
                              context,
                              mobile: 4.0,
                              tablet: 6.0,
                              desktop: 8.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ResponsiveText(
                                  item.designation,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: ResponsiveText(
                                  'Qté: ${item.quantite}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              Expanded(
                                child: ResponsiveText(
                                  formatCurrency.format(item.prixUnitaire),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              Expanded(
                                child: ResponsiveText(
                                  formatCurrency.format(item.total),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  if (devis.items.length > 5)
                    Padding(
                      padding: EdgeInsets.only(
                        top: ResponsiveHelper.getSpacing(
                          context,
                          mobile: 8.0,
                          tablet: 10.0,
                          desktop: 12.0,
                        ),
                      ),
                      child: ResponsiveText(
                        '... et ${devis.items.length - 5} autre${devis.items.length - 5 > 1 ? 's' : ''} article${devis.items.length - 5 > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ResponsiveSpacing(height: 16),
                ],
                // Notes si présentes
                if (devis.notes != null && devis.notes!.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getSpacing(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: ResponsiveHelper.getIconSize(
                                context,
                                mobile: 16.0,
                                tablet: 18.0,
                                desktop: 20.0,
                              ),
                              color: Colors.grey.shade600,
                            ),
                            ResponsiveSpacing(width: 8),
                            ResponsiveText(
                              'Notes:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveHelper.getFontSize(
                                  context,
                                  mobile: 13.0,
                                  tablet: 14.0,
                                  desktop: 15.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ResponsiveSpacing(height: 4),
                        ResponsiveText(
                          devis.notes!,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveSpacing(height: 16),
                ],
                // Boutons d'action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => context.go('/devis/${devis.id}'),
                            icon: Icon(
                              Icons.visibility,
                              size: ResponsiveHelper.getIconSize(context),
                            ),
                            label: const Text('Détails'),
                          ),
                        ),
                        // Modifier : autorisé en attente (1), validé (2) et rejeté (3)
                        if (status == 1 || status == 2 || status == 3) ...[
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => context.go('/devis/${devis.id}/edit'),
                              icon: Icon(
                                Icons.edit,
                                size: ResponsiveHelper.getIconSize(context),
                              ),
                              label: const Text('Modifier'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (status == 2) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await notifier.generatePDF(devis.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PDF généré avec succès'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          Icons.picture_as_pdf,
                          size: ResponsiveHelper.getIconSize(context),
                        ),
                        label: const Text('Générer PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String amount,
    BuildContext context, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getSpacing(
          context,
          mobile: 4.0,
          tablet: 6.0,
          desktop: 8.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 12.0,
                tablet: 13.0,
                desktop: 14.0,
              ),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          ResponsiveText(
            amount,
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(
                context,
                mobile: 12.0,
                tablet: 13.0,
                desktop: 14.0,
              ),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
