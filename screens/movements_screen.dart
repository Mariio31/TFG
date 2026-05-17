import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  List<dynamic> movements = [];
  List<dynamic> products = [];
  bool loading = true;
  bool loadingProducts = true;

  @override
  void initState() {
    super.initState();
    loadMovements();
    loadProducts();
  }

  Future<void> loadMovements() async {
    final data = await ApiService.getMovements();
    setState(() {
      movements = data;
      loading = false;
    });
  }

  Future<void> loadProducts() async {
    final data = await ApiService.getProducts();
    setState(() {
      products = data;
      loadingProducts = false;
    });
  }

  Color typeColor(String type) {
    if (type == 'entrada') return Colors.green;
    if (type == 'salida') return Colors.red;
    return Colors.orange;
  }

  Future<void> openMovementForm() async {
    final _formKey = GlobalKey<FormState>();
    int? selectedProductId;
    final productNameController = TextEditingController();
    String typeValue = 'entrada';
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    final referenceController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          'Crear movimiento',
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
                          loadingProducts
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<int>(
                                  value: selectedProductId,
                                  decoration: const InputDecoration(
                                    labelText: 'Producto',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: products
                                      .map(
                                        (product) => DropdownMenuItem<int>(
                                          value: product['id'] as int,
                                          child: Text(product['name'] ?? '-'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setModalState(() {
                                      selectedProductId = value;
                                      final selected = products.firstWhere(
                                        (product) => product['id'] == value,
                                        orElse: () => null,
                                      );
                                      productNameController.text = selected?['name']?.toString() ?? '';
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) return 'Selecciona un producto';
                                    return null;
                                  },
                                ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: productNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre del producto',
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: typeValue,
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'entrada', child: Text('entrada')),
                              DropdownMenuItem(value: 'salida', child: Text('salida')),
                              DropdownMenuItem(value: 'ajuste', child: Text('ajuste')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() {
                                  typeValue = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: quantityController,
                            decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La cantidad es obligatoria';
                              }
                              if (int.tryParse(value.trim()) == null) {
                                return 'Introduce un número entero';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: reasonController,
                            decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: notesController,
                            decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: referenceController,
                            decoration: const InputDecoration(labelText: 'Referencia', border: OutlineInputBorder()),
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
                                'product_id': selectedProductId,
                                'type': typeValue,
                                'quantity': int.parse(quantityController.text.trim()),
                                'reason': reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                                'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                'reference': referenceController.text.trim().isEmpty ? null : referenceController.text.trim(),
                              }..removeWhere((key, value) => value == null);

                              final success = await ApiService.createMovement(data);
                              if (!mounted) return;
                              if (success) {
                                Navigator.of(context).pop();
                                await loadMovements();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Movimiento creado')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error al crear movimiento')),
                                );
                              }
                            },
                            child: const Text('Crear movimiento'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        elevation: 0,
      ),
      body: RefreshIndicator(
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
                        child: Text(
                          '${m['type'] == 'salida' ? '-' : '+'}${m['quantity']}',
                          style: TextStyle(color: typeColor(m['type']), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openMovementForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
