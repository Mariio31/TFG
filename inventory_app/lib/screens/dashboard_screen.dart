import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/screens/users_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProducts;
  final VoidCallback? onNavigateToCategories;
  final VoidCallback? onNavigateToMovements;
  final VoidCallback? onNavigateToProductsLowStock;

  const DashboardScreen({
    super.key,
    this.onNavigateToProducts,
    this.onNavigateToCategories,
    this.onNavigateToMovements,
    this.onNavigateToProductsLowStock,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> products = [];
  List<dynamic> categories = [];
  List<dynamic> movements = [];
  bool loading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    loadDashboardData();
  }

  Future<void> _loadRole() async {
    final admin = await ApiService.isAdmin();
    if (mounted) setState(() => isAdmin = admin);
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
    final dateStr = movement['created_at'] ?? movement['date'] ?? movement['timestamp'];
    if (dateStr == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
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
                    if (isAdmin) ...[
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.people, color: Colors.blue),
                          ),
                          title: const Text(
                            'Gestión de usuarios',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Crear y eliminar cuentas del equipo',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UsersScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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
                          onTap: widget.onNavigateToProducts,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Cat.',
                          value: categories.length.toString(),
                          icon: Icons.label,
                          color: Colors.blueAccent,
                          onTap: widget.onNavigateToCategories,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Mov.',
                          value: movements.length.toString(),
                          icon: Icons.swap_horiz,
                          color: Colors.lightBlue,
                          onTap: widget.onNavigateToMovements,
                        ),
                        _buildStatCard(
                          context,
                          title: 'Stock bajo',
                          value: lowStockProducts.length.toString(),
                          icon: Icons.warning_amber,
                          color: Colors.redAccent,
                          onTap: widget.onNavigateToProductsLowStock,
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
                              onTap: widget.onNavigateToMovements,
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
                              trailing: const Icon(Icons.chevron_right),
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
                              onTap: widget.onNavigateToProductsLowStock,
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
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      VoidCallback? onTap}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }
}
