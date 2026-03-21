import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/besoin_notifier.dart';

class BesoinFormPage extends ConsumerStatefulWidget {
  const BesoinFormPage({super.key});

  @override
  ConsumerState<BesoinFormPage> createState() => _BesoinFormPageState();
}

class _BesoinFormPageState extends ConsumerState<BesoinFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _reminderFrequency = 'weekly';

  static const List<Map<String, String>> reminderOptions = [
    {'value': 'daily', 'label': 'Tous les jours'},
    {'value': 'every_2_days', 'label': 'Tous les 2 jours'},
    {'value': 'weekly', 'label': 'Toutes les semaines'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(besoinProvider);
    final notifier = ref.read(besoinProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau besoin / Rappel patron'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Le patron sera rappelé automatiquement à la période que vous choisissez, jusqu\'à ce qu\'il traite le besoin.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le titre est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              const Text(
                'Rappeler le patron :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...reminderOptions.map((opt) {
                final value = opt['value']!;
                final label = opt['label']!;
                return RadioListTile<String>(
                  title: Text(label),
                  value: value,
                  groupValue: _reminderFrequency,
                  onChanged: (v) {
                    if (v != null) setState(() => _reminderFrequency = v);
                  },
                );
              }),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => _submit(notifier),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Envoyer au patron'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BesoinNotifier notifier) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire')),
      );
      return;
    }
    final success = await notifier.createBesoin(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      reminderFrequency: _reminderFrequency,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Besoin enregistré. Le patron sera rappelé automatiquement.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/besoins');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
