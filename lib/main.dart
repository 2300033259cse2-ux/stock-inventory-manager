
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'inventory_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.web,
  );

  runApp(const StockInventoryApp());
}

class StockInventoryApp extends StatelessWidget {
  const StockInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stock Inventory Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const StockEntryScreen(),
    );
  }
}

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;

  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _reorderController = TextEditingController();

  String? _selectedCategory;

  final List<String> _categories = [
    'Electronics',
    'Stationery',
    'Hardware',
    'Grocery',
  ];

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_isSaving) return;

    // Validate all required fields before saving.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('stockItems')
          .add({
        'sku': _skuController.text.trim(),
        'itemName': _nameController.text.trim(),
        'category': _selectedCategory!,
        'quantity': int.parse(
          _quantityController.text.trim(),
        ),
        'unitPrice': double.parse(
          _priceController.text.trim(),
        ),
        'reorderLevel': int.parse(
          _reorderController.text.trim(),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock item saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear fields only after successful Firestore write.
      _skuController.clear();
      _nameController.clear();
      _quantityController.clear();
      _priceController.clear();
      _reorderController.clear();

      setState(() {
        _selectedCategory = null;
      });

      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving item: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Form data remains if saving fails.
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _decoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Stock Inventory Manager'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'View Inventory',
            icon: const Icon(Icons.inventory_2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Stock Item',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // SKU
              TextFormField(
                controller: _skuController,
                decoration: _decoration(
                  'SKU (STK-101)',
                  Icons.qr_code,
                ),
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^STK-\d{3}$')
                          .hasMatch(value.trim())) {
                    return 'SKU must be STK- followed by 3 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ITEM NAME
              TextFormField(
                controller: _nameController,
                decoration: _decoration(
                  'Item Name',
                  Icons.inventory,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().length < 3) {
                    return 'Item name must have at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CATEGORY
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _decoration(
                  'Category',
                  Icons.category,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // QUANTITY
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _decoration(
                  'Quantity',
                  Icons.numbers,
                ),
                validator: (value) {
                  final number = int.tryParse(
                    value?.trim() ?? '',
                  );

                  if (number == null || number < 0) {
                    return 'Enter a whole number, 0 or above';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // UNIT PRICE
              TextFormField(
                controller: _priceController,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration(
                  'Unit Price (RM)',
                  Icons.payments,
                ),
                validator: (value) {
                  final number = double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (number == null ||
                      !number.isFinite ||
                      number <= 0) {
                    return 'Enter a price greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // REORDER LEVEL
              TextFormField(
                controller: _reorderController,
                keyboardType: TextInputType.number,
                decoration: _decoration(
                  'Reorder Level',
                  Icons.warning_amber,
                ),
                validator: (value) {
                  final number = int.tryParse(
                    value?.trim() ?? '',
                  );

                  if (number == null || number < 0) {
                    return 'Enter a whole number, 0 or above';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // SAVE BUTTON
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveItem,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving Item...'
                      : 'Save Item',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
