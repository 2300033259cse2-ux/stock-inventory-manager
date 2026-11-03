
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() =>
      _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  String _selectedCategory = 'All';
  bool _lowStockOnly = false;
  bool _ascending = true;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Stationery',
    'Hardware',
    'Grocery',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _lowStockOnly = false;
      _ascending = true;
    });
  }

  int _getInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _getDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Inventory'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SEARCH AND FILTER CONTROLS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search SKU or Item Name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'All';
                    });
                  },
                ),

                SwitchListTile(
                  title: const Text('Low Stock Only'),
                  subtitle: const Text(
                    'Quantity <= Reorder Level',
                  ),
                  value: _lowStockOnly,
                  onChanged: (value) {
                    setState(() {
                      _lowStockOnly = value;
                    });
                  },
                ),

                Row(
                  children: [
                    const Text('Sort Quantity: '),
                    Expanded(
                      child: DropdownButton<bool>(
                        isExpanded: true,
                        value: _ascending,
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text('Ascending'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Descending'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _ascending = value ?? true;
                          });
                        },
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // LIVE FIRESTORE INVENTORY
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('stockItems')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load inventory. '
                          'Check your connection and permissions.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allItems = snapshot.data!.docs;

                if (allItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No inventory items saved yet.',
                    ),
                  );
                }

                final keyword = _searchController.text
                    .trim()
                    .toLowerCase();

                final filteredItems = allItems.where((doc) {
                  final item = doc.data();

                  final sku =
                  (item['sku'] ?? '').toString().toLowerCase();

                  final name = (item['itemName'] ?? '')
                      .toString()
                      .toLowerCase();

                  final category =
                  (item['category'] ?? '').toString();

                  final quantity = _getInt(item['quantity']);

                  final reorder =
                  _getInt(item['reorderLevel']);

                  // Name OR SKU keyword match.
                  final matchesKeyword =
                      keyword.isEmpty ||
                          sku.contains(keyword) ||
                          name.contains(keyword);

                  // Category filter.
                  final matchesCategory =
                      _selectedCategory == 'All' ||
                          category == _selectedCategory;

                  // Low stock filter.
                  final matchesLowStock =
                      !_lowStockOnly ||
                          quantity <= reorder;

                  // AND between active filters.
                  return matchesKeyword &&
                      matchesCategory &&
                      matchesLowStock;
                }).toList();

                // Sort visible records by quantity.
                filteredItems.sort((a, b) {
                  final qtyA =
                  _getInt(a.data()['quantity']);
                  final qtyB =
                  _getInt(b.data()['quantity']);

                  return _ascending
                      ? qtyA.compareTo(qtyB)
                      : qtyB.compareTo(qtyA);
                });

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching stock items found.\n'
                          'Try clearing the filters.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item =
                    filteredItems[index].data();

                    final sku =
                    (item['sku'] ?? '').toString();

                    final name =
                    (item['itemName'] ?? '').toString();

                    final category =
                    (item['category'] ?? '').toString();

                    final quantity =
                    _getInt(item['quantity']);

                    final reorder =
                    _getInt(item['reorderLevel']);

                    final price =
                    _getDouble(item['unitPrice']);

                    final isLowStock = quantity <= reorder;

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('SKU: $sku'),
                            Text('Category: $category'),
                            Text('Quantity: $quantity'),
                            Text(
                              'Unit Price: RM ${price.toStringAsFixed(2)}',
                            ),
                            Text('Reorder Level: $reorder'),

                            if (isLowStock)
                              const Padding(
                                padding: EdgeInsets.only(
                                  top: 8,
                                ),
                                child: Text(
                                  'LOW STOCK',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
