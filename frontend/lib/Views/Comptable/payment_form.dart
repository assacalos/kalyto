import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easyconnect/providers/payment_notifier.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class PaymentForm extends ConsumerStatefulWidget {
  final int? paymentId;

  const PaymentForm({super.key, this.paymentId});

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  bool _isLoading = true;
  bool _isCreating = false;
  String _paymentType = 'one_time';
  DateTime _paymentDate = DateTime.now();
  DateTime? _dueDate;
  double _amount = 0.0;
  String _paymentMethod = 'bank_transfer';
  int _selectedClientId = 0;
  String _selectedClientName = '';
  String _selectedClientEmail = '';
  String _selectedClientAddress = '';
  DateTime _scheduleStartDate = DateTime.now();
  DateTime _scheduleEndDate = DateTime.now().add(const Duration(days: 365));
  int _frequency = 30;
  int _totalInstallments = 12;
  double _installmentAmount = 0.0;
  String _generatedReference = '';

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientEmailController = TextEditingController();
  final TextEditingController clientAddressController = TextEditingController();

  bool _referenceRequested = false;
  bool _loadEditRequested = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentId == null) {
      setState(() => _isLoading = false);
    }
  }

  void _requestGeneratedReference() {
    if (_referenceRequested || _generatedReference.isNotEmpty) return;
    _referenceRequested = true;
    ref.read(paymentProvider.notifier).generatePaymentReference().then((ref) {
      if (mounted) {
        setState(() {
          _generatedReference = ref;
          referenceController.text = ref;
        });
      }
    });
  }

  void _loadPaymentForEditIfNeeded() {
    if (widget.paymentId == null || !_isLoading || _loadEditRequested) return;
    _loadEditRequested = true;
    _loadPaymentForEdit();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    notesController.dispose();
    referenceController.dispose();
    clientNameController.dispose();
    clientEmailController.dispose();
    clientAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentForEdit() async {
    try {
      final notifier = ref.read(paymentProvider.notifier);
      final payment = await notifier.getPaymentById(widget.paymentId!);
      if (!mounted) return;
      setState(() {
        _selectedClientId = payment.clientId;
        _selectedClientName = payment.clientName;
        _selectedClientEmail = payment.clientEmail;
        _selectedClientAddress = payment.clientAddress;
        _paymentType = payment.type;
        _paymentDate = payment.paymentDate;
        _dueDate = payment.dueDate;
        _amount = payment.amount;
        _paymentMethod = payment.paymentMethod;
        descriptionController.text = payment.description ?? '';
        notesController.text = payment.notes ?? '';
        referenceController.text = payment.reference ?? '';
        clientNameController.text = payment.clientName;
        clientEmailController.text = payment.clientEmail;
        clientAddressController.text = payment.clientAddress;
        if (payment.schedule != null) {
          _scheduleStartDate = payment.schedule!.startDate;
          _scheduleEndDate = payment.schedule!.endDate;
          _frequency = payment.schedule!.frequency;
          _totalInstallments = payment.schedule!.totalInstallments;
          _installmentAmount = payment.schedule!.installmentAmount;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger le paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier un paiement'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const SkeletonPage(listItemCount: 6),
      );
    }
    if (!_referenceRequested && widget.paymentId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestGeneratedReference());
    }
    if (_isLoading && widget.paymentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPaymentForEditIfNeeded());
    }
    final notifier = ref.read(paymentProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paymentId != null
              ? 'Modifier un paiement'
              : 'Créer un paiement',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentTypeSection(),
            const SizedBox(height: 20),
            _buildClientSection(notifier),
            const SizedBox(height: 20),
            _buildPaymentDetailsSection(),
            const SizedBox(height: 20),
            if (_paymentType == 'monthly') ...[
              _buildScheduleSection(),
              const SizedBox(height: 20),
            ],
            _buildNotesSection(),
            const SizedBox(height: 20),
            _buildSummarySection(),
            const SizedBox(height: 20),
            _buildSaveButton(notifier),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(PaymentNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isCreating
              ? null
              : () async {
                  setState(() => _isCreating = true);
                  try {
                    final schedule = _paymentType == 'monthly'
                        ? PaymentSchedule(
                            id: 0,
                            startDate: DateTime(_scheduleStartDate.year, _scheduleStartDate.month, _scheduleStartDate.day),
                            endDate: DateTime(_scheduleEndDate.year, _scheduleEndDate.month, _scheduleEndDate.day),
                            frequency: _frequency,
                            totalInstallments: _totalInstallments,
                            paidInstallments: 0,
                            installmentAmount: _amount / _totalInstallments,
                            status: 'active',
                            nextPaymentDate: _scheduleStartDate,
                            installments: [],
                          )
                        : null;
                    final success = await notifier.createPayment(
                      clientId: _selectedClientId,
                      clientName: _selectedClientName,
                      clientEmail: _selectedClientEmail,
                      clientAddress: _selectedClientAddress,
                      type: _paymentType,
                      paymentDate: _paymentDate,
                      dueDate: _dueDate,
                      amount: _amount,
                      paymentMethod: _paymentMethod,
                      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      reference: _generatedReference.isNotEmpty ? _generatedReference : (referenceController.text.trim().isEmpty ? null : referenceController.text.trim()),
                      schedule: schedule,
                    );
                    if (mounted) {
                      if (success) {
                        await notifier.loadPayments();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paiement créé avec succès'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isCreating = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isCreating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Créer le paiement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Ponctuel'),
                    subtitle: const Text('Paiement unique'),
                    value: 'one_time',
                    groupValue: _paymentType,
                    onChanged: (value) => setState(() => _paymentType = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Mensuel'),
                    subtitle: const Text('Paiements récurrents'),
                    value: 'monthly',
                    groupValue: _paymentType,
                    onChanged: (value) => setState(() => _paymentType = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection(PaymentNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Informations client',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () => _showClientSelectionDialog(notifier),
                    icon: const Icon(Icons.person_search, size: 18),
                    label: const Text(
                      'Sélectionner',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                if (_selectedClientId > 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Client sélectionné: $_selectedClientName',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedClientId = 0;
                              clientNameController.clear();
                              clientEmailController.clear();
                              clientAddressController.clear();
                              _selectedClientName = '';
                              _selectedClientEmail = '';
                              _selectedClientAddress = '';
                            });
                          },
                          child: const Text('Réinitialiser'),
                        ),
                      ],
                    ),
                  ),
                if (_selectedClientId > 0) const SizedBox(height: 16),
                TextField(
                  controller: clientNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du client *',
                    border: const OutlineInputBorder(),
                    enabled: _selectedClientId == 0,
                    filled: _selectedClientId > 0,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) => setState(() => _selectedClientName = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: clientEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email du client *',
                    border: const OutlineInputBorder(),
                    enabled: _selectedClientId == 0,
                    filled: _selectedClientId > 0,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) => setState(() => _selectedClientEmail = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: clientAddressController,
                  decoration: InputDecoration(
                    labelText: 'Adresse du client *',
                    border: const OutlineInputBorder(),
                    enabled: _selectedClientId == 0,
                    filled: _selectedClientId > 0,
                    fillColor: Colors.grey[200],
                  ),
                  maxLines: 2,
                  onChanged: (value) => setState(() => _selectedClientAddress = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de paiement'),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) setState(() => _paymentDate = date);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date d\'échéance'),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) setState(() => _dueDate = date);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _dueDate != null
                              ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                              : 'Sélectionner',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _amount = double.tryParse(value) ?? 0.0),
                    decoration: const InputDecoration(
                      labelText: 'Montant *',
                      border: OutlineInputBorder(),
                      prefixText: 'fcfa ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Méthode de paiement',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('Virement banque'),
                      ),
                      DropdownMenuItem(value: 'check', child: Text('Chèque')),
                      DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                      DropdownMenuItem(
                        value: 'card',
                        child: Text('Carte bancaire'),
                      ),
                      DropdownMenuItem(
                        value: 'direct_debit',
                        child: Text('Prélèvement'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Planning des paiements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de début'),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _scheduleStartDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => _scheduleStartDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            ));
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${_scheduleStartDate.day}/${_scheduleStartDate.month}/${_scheduleStartDate.year}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de fin'),
                      TextButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _scheduleEndDate,
                            firstDate: _scheduleStartDate,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 5),
                            ),
                          );
                          if (date != null) {
                            setState(() => _scheduleEndDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            ));
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${_scheduleEndDate.day}/${_scheduleEndDate.month}/${_scheduleEndDate.year}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _frequency.toString()),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _frequency = parsed;
                          if (_amount > 0) _installmentAmount = _amount / parsed;
                        });
                      } else if (value.isEmpty) {
                        setState(() => _frequency = 30);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Fréquence (jours) *',
                      border: OutlineInputBorder(),
                      suffixText: 'jours',
                      helperText:
                          'Nombre de jours entre chaque paiement (min: 1)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _totalInstallments.toString()),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _totalInstallments = parsed;
                          if (_amount > 0) _installmentAmount = _amount / parsed;
                        });
                      } else if (value.isEmpty) {
                        setState(() => _totalInstallments = 12);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nombre d\'échéances *',
                      border: OutlineInputBorder(),
                      helperText: 'Nombre total de paiements (min: 1)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Montant par échéance: ${_installmentAmount.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes et références',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence (générée automatiquement)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey,
                helperText: 'Référence générée automatiquement',
              ),
              readOnly: true,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildSummaryRow(
                  'Type',
                  PaymentNotifier.getPaymentTypeName(_paymentType),
                ),
                _buildSummaryRow(
                  'Montant',
                  '${_amount.toStringAsFixed(2)} €',
                ),
                _buildSummaryRow(
                  'Méthode',
                  PaymentNotifier.getPaymentMethodName(_paymentMethod),
                ),
                if (_paymentType == 'monthly') ...[
                  _buildSummaryRow(
                    'Échéances',
                    '$_totalInstallments',
                  ),
                  _buildSummaryRow(
                    'Fréquence',
                    '$_frequency jours',
                  ),
                  _buildSummaryRow(
                    'Montant par échéance',
                    '${_installmentAmount.toStringAsFixed(2)} fcfa',
                  ),
                ],
                const Divider(),
                _buildSummaryRow(
                  'Total',
                  '${_amount.toStringAsFixed(2)} fcfa',
                  isTotal: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.green : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClientSelectionDialog(PaymentNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => ClientSelectionDialog(
        onClientSelected: (Client client) {
          final clientName =
              client.nomEntreprise?.isNotEmpty == true
                  ? client.nomEntreprise!
                  : '${client.nom ?? ''} ${client.prenom ?? ''}'
                      .trim()
                      .isNotEmpty
                  ? '${client.nom ?? ''} ${client.prenom ?? ''}'.trim()
                  : 'Client #${client.id}';
          final addressParts = <String>[];
          if (client.adresse != null && client.adresse!.isNotEmpty) {
            addressParts.add(client.adresse!);
          }
          final clientAddress =
              addressParts.isEmpty
                  ? 'Non spécifiée'
                  : addressParts.join(', ');
          setState(() {
            _selectedClientId = client.id ?? 0;
            _selectedClientName = clientName;
            _selectedClientEmail = client.email ?? '';
            _selectedClientAddress = clientAddress;
            clientNameController.text = clientName;
            clientEmailController.text = client.email ?? '';
            clientAddressController.text = clientAddress;
          });
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les informations du client ont été remplies automatiquement'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
