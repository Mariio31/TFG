import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  List<dynamic> movements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMovements();
  }

  Future<void> loadMovements() async {
    final data = await ApiService.getMovements();
    setState(() { movements = data; loading = false; });
  }

  Color typeColor(String type) {
    if (type == 'entrada') return Colors.green;
    if (type == 'salida') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: loadMovements,
      child: movements.isEmpty
          ? const Center(child: Text('No hay movimientos aún'))
          : ListView.builder(
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final m = movements[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeColor(m['type']).withOpacity(0.2),
                      child: Icon(
                        m['type'] == 'entrada' ? Icons.arrow_downward : m['type'] == 'salida' ? Icons.arrow_upward : Icons.swap_horiz,
                        color: typeColor(m['type']),
                      ),
                    ),
                    title: Text(m['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(m['reason'] ?? 'Sin motivo'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor(m['type']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${m['type'] == 'salida' ? '-' : '+'}${m['quantity']}',
                        style: TextStyle(color: typeColor(m['type']), fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}