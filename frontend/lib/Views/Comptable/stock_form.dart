import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/providers/stock_notifier.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class StockForm extends ConsumerStatefulWidget {
  final Stock? stock;

  const StockForm({super.key, this.stock});

  @override
  ConsumerState<StockForm> createState() => _StockFormState();
}

class _StockFormState extends ConsumerState<StockForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _maxQuantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = '';

  static const _stockCategories = [
    {'value': 'electronics', 'label': 'Électronique'},
    {'value': 'clothing', 'label': 'Vêtements'},
    {'value': 'food', 'label': 'Alimentation'},
    {'value': 'books', 'label': 'Livres'},
    {'value': 'tools', 'label': 'Outils'},
    {'value': 'furniture', 'label': 'Mobilier'},
    {'value': 'sports', 'label': 'Sport'},
    {'value': 'beauty', 'label': 'Beauté'},
    {'value': 'automotive', 'label': 'Automobile'},
    {'value': 'other', 'label': 'Autre'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockProvider.notifier).loadCategories();
      if (widget.stock != null) _fillForm(widget.stock!);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillForm(Stock s) {
    _nameController.text = s.name;
    _descriptionController.text = s.description ?? '';
    _skuController.text = s.sku;
    _quantityController.text = s.quantity.toString();
    _minQuantityController.text = s.minQuantity.toString();
    _maxQuantityController.text = s.maxQuantity.toString();
    _unitPriceController.text = s.unitPrice.toString();
    _notesController.text = s.commentaire ?? '';
    _selectedCategory = s.category;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stock == null ? 'Nouveau Produit' : 'Modifier le Produit',
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveStock,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informations de base'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le nom est obligatoire';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Description du produit (optionnel)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _stockCategories.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem<String>(
                    value: c['value'] as String,
                    child: Text(c['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'La catégorie est obligatoire';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU (Code produit) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                  hintText: 'Code unique du produit',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le SKU est obligatoire';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations de stock'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité initiale *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'La quantité est obligatoire';
                  if (double.tryParse(value) == null) return 'La quantité doit être un nombre';
                  if (double.parse(value) < 0) return 'La quantité ne peut pas être négative';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Seuil minimum *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                        hintText: 'Alerte stock faible',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Le seuil minimum est obligatoire';
                        if (double.tryParse(value) == null) return 'Le seuil minimum doit être un nombre';
                        if (double.parse(value) < 0) return 'Le seuil minimum ne peut pas être négatif';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxQuantityController,
                      decoration: const InputDecoration(
                        labelText: 'Seuil maximum *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                        hintText: 'Alerte surstock',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Le seuil maximum est obligatoire';
                        if (double.tryParse(value) == null) return 'Le seuil maximum doit être un nombre';
                        if (double.parse(value) < 0) return 'Le seuil maximum ne peut pas être négatif';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire (fcfa) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le prix unitaire est obligatoire';
                  if (double.tryParse(value) == null) return 'Le prix unitaire doit être un nombre';
                  if (double.parse(value) < 0) return 'Le prix unitaire ne peut pas être négatif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Commentaire optionnel',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              UniformFormButtons(
                onCancel: () => context.pop(),
                onSubmit: _saveStock,
                submitText: 'Soumettre',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple,
      ),
    );
  }

  Future<void> _saveStock() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final minQty = double.tryParse(_minQuantityController.text.trim()) ?? 0;
    final maxQty = double.tryParse(_maxQuantityController.text.trim()) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0;

    final notifier = ref.read(stockProvider.notifier);

    if (widget.stock == null) {
      final stock = Stock(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        category: _selectedCategory,
        sku: _skuController.text.trim(),
        unit: 'pièce',
        quantity: quantity,
        minQuantity: minQty,
        maxQuantity: maxQty,
        unitPrice: unitPrice,
        commentaire: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        status: 'en_attente',
      );
      final created = await notifier.createStock(stock);
      if (!mounted) return;
      if (created != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/stocks');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du produit')),
        );
      }
    } else {
      final stock = widget.stock!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        category: _selectedCategory,
        sku: _skuController.text.trim(),
        quantity: quantity,
        minQuantity: minQty,
        maxQuantity: maxQty,
        unitPrice: unitPrice,
        commentaire: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
      final success = await notifier.updateStock(stock);
      if (!mounted) return;
      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        context.go('/stocks');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour du produit')),
        );
      }
    }
  }
}
