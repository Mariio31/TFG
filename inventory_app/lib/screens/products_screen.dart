import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await ApiService.getProducts();
    setState(() { products = data; loading = false; });
  }

  Future<void> handleDelete(int id) async {
    await ApiService.deleteProduct(id);
    loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: loadProducts,
      child: products.isEmpty
          ? const Center(child: Text('No hay productos aún'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                final lowStock = p['stock'] <= p['min_stock'];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lowStock ? Colors.red[100] : Colors.green[100],
                      child: Text('${p['stock']}', style: TextStyle(color: lowStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('SKU: ${p['sku'] ?? '-'} | ${p['price']}€'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => handleDelete(p['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}