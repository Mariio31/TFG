import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool loading = true;
  String currentFilter = 'Todos';

  static const List<String> units = [
    'unidad',
    'kg',
    'litro',
    'caja',
    'paquete',
    'metro',
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    final data = await ApiService.getProducts();
    setState(() {
      products = data;
      filteredProducts = data;
      loading = false;
    });
  }

  void filterProducts(String query) {
    final lower = query.toLowerCase();
    setState(() {
      filteredProducts = products.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final sku = (item['sku'] ?? '').toString().toLowerCase();
        final matchesQuery = name.contains(lower) || sku.contains(lower);

        if (currentFilter == 'Stock bajo') {
          final stock = int.tryParse(item['stock']?.toString() ?? '0') ?? 0;
          final minStock = int.tryParse(item['min_stock']?.toString() ?? '0') ?? 0;
          return matchesQuery && stock <= minStock;
        }

        return matchesQuery;
      }).toList();
    });
  }

  void applyFilterOption(String option) {
    setState(() {
      currentFilter = option;
    });
    filterProducts(searchController.text);
  }

  Future<void> handleDelete(int id) async {
    await ApiService.deleteProduct(id);
    await loadProducts();
  }

  Future<void> openProductForm([Map<String, dynamic>? product]) async {
    final isEditing = product != null;
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final skuController = TextEditingController(text: product?['sku'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    final categoryController = TextEditingController(text: product?['category_id']?.toString() ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final costController = TextEditingController(text: product?['cost']?.toString() ?? '');
    final stockController = TextEditingController(text: product?['stock']?.toString() ?? '');
    final minStockController = TextEditingController(text: product?['min_stock']?.toString() ?? '');
    final supplierController = TextEditingController(text: product?['supplier'] ?? '');
    String unitValue = product?['unit']?.toString() ?? 'unidad';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar producto' : 'Crear producto',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: skuController,
                        decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Category ID', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: units.contains(unitValue) ? unitValue : 'unidad',
                        items: units.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                        decoration: const InputDecoration(labelText: 'Unidad', border: OutlineInputBorder()),
                        onChanged: (value) {
                          if (value != null) {
                            unitValue = value;
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: costController,
                        decoration: const InputDecoration(labelText: 'Coste', border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: stockController,
                        decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: minStockController,
                        decoration: const InputDecoration(labelText: 'Stock mínimo', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: supplierController,
                        decoration: const InputDecoration(labelText: 'Proveedor', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState?.validate() != true) return;
                          final data = <String, dynamic>{
                            'name': nameController.text.trim(),
                            'sku': skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                            'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                            'category_id': categoryController.text.trim().isEmpty ? null : int.tryParse(categoryController.text.trim()),
                            'price': priceController.text.trim().isEmpty ? null : double.tryParse(priceController.text.trim()),
                            'cost': costController.text.trim().isEmpty ? null : double.tryParse(costController.text.trim()),
                            'stock': stockController.text.trim().isEmpty ? null : int.tryParse(stockController.text.trim()),
                            'min_stock': minStockController.text.trim().isEmpty ? null : int.tryParse(minStockController.text.trim()),
                            'unit': unitValue,
                            'supplier': supplierController.text.trim().isEmpty ? null : supplierController.text.trim(),
                          }..removeWhere((key, value) => value == null);

                          final success = isEditing
                              ? await ApiService.updateProduct(product!['id'], data)
                              : await ApiService.createProduct(data);

                          if (!mounted) return;
                          if (success) {
                            Navigator.of(context).pop();
                            await loadProducts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEditing ? 'Producto actualizado' : 'Producto creado')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error al guardar el producto')),
                            );
                          }
                        },
                        child: Text(isEditing ? 'Guardar cambios' : 'Crear producto'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showProductDetails(Map<String, dynamic> p) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p['name'] ?? 'Producto', style: Theme.of(context).textTheme.headlineSmall),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 8),
                _detailRow('SKU', p['sku']?.toString() ?? '-'),
                _detailRow('Descripción', p['description']?.toString() ?? '-'),
                _detailRow('Categoría (ID)', p['category_id']?.toString() ?? '-'),
                _detailRow('Precio', p['price']?.toString() ?? '-'),
                _detailRow('Coste', p['cost']?.toString() ?? '-'),
                _detailRow('Stock actual', p['stock']?.toString() ?? '0'),
                _detailRow('Stock mínimo', p['min_stock']?.toString() ?? '0'),
                _detailRow('Unidad', p['unit']?.toString() ?? '-'),
                _detailRow('Proveedor', p['supplier']?.toString() ?? '-'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: filterProducts,
                      decoration: InputDecoration(
                        labelText: 'Buscar por nombre o SKU',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: applyFilterOption,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Todos', child: Text('Todos')),
                      PopupMenuItem(value: 'Stock bajo', child: Text('Stock bajo')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('No hay productos que coincidan'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final p = filteredProducts[index];
                        final stock = int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
                        final minStock = int.tryParse(p['min_stock']?.toString() ?? '0') ?? 0;
                        final lowStock = stock <= minStock;
                        final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0.0;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            onTap: () => openProductForm(p),
                            onLongPress: () => showProductDetails(p),
                            leading: CircleAvatar(
                              backgroundColor: lowStock ? Colors.red.shade100 : Colors.green.shade100,
                              child: Text(
                                '$stock',
                                style: TextStyle(
                                  color: lowStock ? Colors.red.shade700 : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(p['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SKU: ${p['sku'] ?? '-'}'),
                                const SizedBox(height: 4),
                                Text('Precio: ${price.toStringAsFixed(2)} €'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red.shade700),
                              onPressed: () => handleDelete(p['id']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openProductForm(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
