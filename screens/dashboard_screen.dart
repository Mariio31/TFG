import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> products = [];
  List<dynamic> categories = [];
  List<dynamic> movements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    setState(() {
      loading = true;
    });

    final productData = await ApiService.getProducts();
    final categoryData = await ApiService.getCategories();
    final movementData = await ApiService.getMovements();

    if (mounted) {
      setState(() {
        products = productData;
        categories = categoryData;
        movements = movementData;
        loading = false;
      });
    }
  }

  List<dynamic> get lowStockProducts {
    return products.where((product) {
      final stock = (product['stock'] is num ? product['stock'] as num : num.tryParse(product['stock']?.toString() ?? '') ?? 0).toInt();
      final minStock = (product['min_stock'] is num ? product['min_stock'] as num : num.tryParse(product['min_stock']?.toString() ?? '') ?? 0).toInt();
      return stock <= minStock;
    }).toList();
  }

  List<dynamic> get latestMovements {
    final list = List<dynamic>.from(movements);
    if (list.length <= 5) return list.reversed.toList();
    return list.reversed.take(5).toList();
  }

  String formatMovementTitle(dynamic movement) {
    final type = movement['type']?.toString() ?? '';
    final quantity = movement['quantity']?.toString() ?? '';
    final productName = movement['product_name']?.toString() ?? movement['product']?.toString() ?? 'Producto';
    return '$productName • $type • $quantity';
  }

  String formatMovementSubtitle(dynamic movement) {
    final date = movement['created_at'] ?? movement['date'] ?? movement['timestamp'];
    return date?.toString() ?? 'Sin fecha';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Resumen',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visión general de tu inventario y movimientos recientes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          context,
                          title: 'Productos',
                          value: products.length.toString(),
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Categorías',
                          value: categories.length.toString(),
                          icon: Icons.label,
                          color: Colors.blueAccent,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Movimientos',
                          value: movements.length.toString(),
                          icon: Icons.swap_horiz,
                          color: Colors.lightBlue,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Stock bajo',
                          value: lowStockProducts.length.toString(),
                          icon: Icons.warning_amber,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Últimos movimientos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (latestMovements.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No hay movimientos recientes.'),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: latestMovements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final movement = latestMovements[index];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  movement['type'] == 'salida'
                                      ? Icons.arrow_upward
                                      : movement['type'] == 'entrada'
                                          ? Icons.arrow_downward
                                          : Icons.swap_horiz,
                                  color: Colors.blue,
                                ),
                              ),
                              title: Text(formatMovementTitle(movement)),
                              subtitle: Text(formatMovementSubtitle(movement)),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Productos con stock bajo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (lowStockProducts.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No hay productos con stock bajo.'),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lowStockProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = lowStockProducts[index];
                          final stock = product['stock']?.toString() ?? '0';
                          final minStock = product['min_stock']?.toString() ?? '0';
                          return Card(
                            color: Colors.red.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              title: Text(
                                product['name']?.toString() ?? 'Producto desconocido',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Stock: $stock • Mínimo: $minStock'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Bajo',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 24,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
