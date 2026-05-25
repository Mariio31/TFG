import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/utils/confirm_dialogs.dart';
import 'package:inventory_app/widgets/back_leading.dart';

class MovementsScreen extends StatefulWidget {
  final VoidCallback? onBackToMenu;
  const MovementsScreen({super.key, this.onBackToMenu});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  static const int _pageSize = 20;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> movements = [];
  List<dynamic> filteredMovements = [];
  List<dynamic> products = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMoreMovements = true;
  bool loadingProducts = true;
  bool canEdit = false;
  String selectedTypeFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    loadMovements();
    loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        loading ||
        loadingMore ||
        !hasMoreMovements) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      loadMoreMovements();
    }
  }

  Future<void> _loadPermissions() async {
    final edit = await ApiService.canEdit();
    if (mounted) setState(() => canEdit = edit);
  }

  Future<void> loadMovements() async {
    setState(() => loading = true);
    final data = await ApiService.getMovements(skip: 0, limit: _pageSize);
    setState(() {
      movements = data;
      hasMoreMovements = data.length == _pageSize;
      loadingMore = false;
      loading = false;
    });
    filterMovements(searchController.text);
  }

  Future<void> loadMoreMovements() async {
    setState(() => loadingMore = true);
    final data = await ApiService.getMovements(
      skip: movements.length,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      movements.addAll(data);
      hasMoreMovements = data.length == _pageSize;
      loadingMore = false;
    });
    filterMovements(searchController.text);
  }

  void filterMovements(String query) {
    final lower = query.toLowerCase();
    setState(() {
      filteredMovements = movements.where((item) {
        final productName = (item['product_name'] ?? '')
            .toString()
            .toLowerCase();
        final reference = (item['reference'] ?? '').toString().toLowerCase();
        final type = (item['type'] ?? '').toString().toLowerCase();
        final matchesQuery =
            productName.contains(lower) || reference.contains(lower);

        if (selectedTypeFilter != 'Todos') {
          final selectedType = selectedTypeFilter.toLowerCase();
          if (selectedType == 'traspaso') {
            if (type != 'traspaso' && type != 'ajuste') return false;
          } else if (type != selectedType) {
            return false;
          }
        }

        return matchesQuery;
      }).toList();
    });
  }

  void applyTypeFilter(String? value) {
    if (value == null) return;
    setState(() => selectedTypeFilter = value);
    filterMovements(searchController.text);
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

  String formatMovementDate(dynamic movement) {
    final dateStr =
        movement['created_at'] ?? movement['date'] ?? movement['timestamp'];
    if (dateStr == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  Future<void> _confirmDeleteMovement(dynamic movement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Eliminar este movimiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ApiService.deleteMovement(movement['id']);
      if (!mounted) return;
      if (success) {
        await loadMovements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento eliminado'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el movimiento'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> openMovementForm([dynamic movement]) async {
    final _formKey = GlobalKey<FormState>();
    int? selectedProductId = movement?['product_id'];
    final productNameController = TextEditingController(
      text: movement?['product_name']?.toString() ?? '',
    );
    String typeValue = movement?['type'] ?? 'entrada';
    final quantityController = TextEditingController(
      text: movement?['quantity']?.toString() ?? '',
    );
    final reasonController = TextEditingController(
      text: movement?['reason']?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: movement?['notes']?.toString() ?? '',
    );
    final referenceController = TextEditingController(
      text: movement?['reference']?.toString() ?? '',
    );
    DateTime selectedDate = DateTime.now();

    final isEditMode = movement != null;
    final initialProductId = selectedProductId;
    final initialProductName = productNameController.text;
    final initialType = typeValue;
    final initialQuantity = quantityController.text;
    final initialReason = reasonController.text;
    final initialNotes = notesController.text;
    final initialReference = referenceController.text;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool hasUnsavedChanges() {
              if (!isEditMode) return false;
              if (selectedProductId != initialProductId) return true;
              if (productNameController.text.trim() !=
                  initialProductName.trim()) {
                return true;
              }
              if (typeValue != initialType) return true;
              if (quantityController.text.trim() != initialQuantity.trim())
                return true;
              if (reasonController.text.trim() != initialReason.trim())
                return true;
              if (notesController.text.trim() != initialNotes.trim())
                return true;
              if (referenceController.text.trim() != initialReference.trim()) {
                return true;
              }
              return false;
            }

            return FormDiscardPopScope(
              isEditMode: isEditMode,
              hasUnsavedChanges: hasUnsavedChanges,
              child: Padding(
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
                            movement == null
                                ? 'Crear movimiento'
                                : 'Editar movimiento',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => closeFormSheet(
                              context,
                              isEditMode: isEditMode,
                              hasUnsavedChanges: hasUnsavedChanges,
                            ),
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
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
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
                                        productNameController.text =
                                            selected?['name']?.toString() ?? '';
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null)
                                        return 'Selecciona un producto';
                                      return null;
                                    },
                                  ),

                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: typeValue,
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'entrada',
                                  child: Text('entrada'),
                                ),
                                DropdownMenuItem(
                                  value: 'salida',
                                  child: Text('salida'),
                                ),
                                DropdownMenuItem(
                                  value: 'ajuste',
                                  child: Text('ajuste'),
                                ),
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
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                border: OutlineInputBorder(),
                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'Motivo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notas',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: referenceController,
                              decoration: const InputDecoration(
                                labelText: 'Referencia',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (!isEditMode) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}",
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState?.validate() != true)
                                  return;
                                if (movement != null) {
                                  final confirmed = await confirmSaveChanges(
                                    context,
                                  );
                                  if (!confirmed) return;
                                }

                                // Construir el body con tipos correctos
                                final data = <String, dynamic>{
                                  'product_id': selectedProductId is String
                                      ? int.parse(selectedProductId as String)
                                      : selectedProductId,
                                  'product_name': productNameController.text
                                      .trim(),
                                  'type': typeValue.toLowerCase(),
                                  'quantity': int.parse(
                                    quantityController.text.trim(),
                                  ),
                                  'reason': reasonController.text.trim().isEmpty
                                      ? null
                                      : reasonController.text.trim(),
                                  'notes': notesController.text.trim().isEmpty
                                      ? null
                                      : notesController.text.trim(),
                                  'reference':
                                      referenceController.text.trim().isEmpty
                                      ? null
                                      : referenceController.text.trim(),
                                }..removeWhere((key, value) => value == null);

                                if (!isEditMode) {
                                  data['created_at'] = selectedDate.toIso8601String();
                                }

                                final success = movement == null
                                    ? await ApiService.createMovement(data)
                                    : await ApiService.updateMovement(
                                        movement['id'],
                                        data,
                                      );
                                if (!mounted) return;
                                if (success) {
                                  Navigator.of(context).pop();
                                  await loadMovements();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        movement == null
                                            ? '✓ Movimiento creado correctamente'
                                            : '✓ Movimiento actualizado correctamente',
                                      ),
                                      backgroundColor: Colors.green[600],
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        movement == null
                                            ? '✗ Error al crear el movimiento'
                                            : '✗ Error al actualizar el movimiento',
                                      ),
                                      backgroundColor: Colors.red[600],
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                movement == null
                                    ? 'Crear movimiento'
                                    : 'Guardar cambios',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        leading: buildBackLeading(context, onBackToMenu: widget.onBackToMenu),
        automaticallyImplyLeading: false,
        title: const Text('Movimientos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: filterMovements,
                    decoration: InputDecoration(
                      labelText: 'Buscar por producto o referencia',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTypeFilter,
                      icon: const Icon(Icons.filter_list),
                      onChanged: applyTypeFilter,
                      items: const [
                        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'Entrada',
                          child: Text('Entrada'),
                        ),
                        DropdownMenuItem(
                          value: 'Salida',
                          child: Text('Salida'),
                        ),
                        DropdownMenuItem(
                          value: 'Traspaso',
                          child: Text('Traspaso'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadMovements,
              child: filteredMovements.isEmpty
                  ? const Center(
                      child: Text('No hay movimientos que coincidan'),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          filteredMovements.length + (loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredMovements.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final m = filteredMovements[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            onTap: canEdit ? () => openMovementForm(m) : null,
                            leading: CircleAvatar(
                              backgroundColor: typeColor(
                                m['type'],
                              ).withOpacity(0.2),
                              child: Icon(
                                m['type'] == 'entrada'
                                    ? Icons.arrow_downward
                                    : m['type'] == 'salida'
                                    ? Icons.arrow_upward
                                    : Icons.swap_horiz,
                                color: typeColor(m['type']),
                              ),
                            ),
                            title: Text(
                              m['product_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['reason'] ?? 'Sin motivo'),
                                const SizedBox(height: 4),
                                Text(
                                  formatMovementDate(m),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor(m['type']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${m['type'] == 'salida' ? '-' : '+'}${m['quantity']}',
                                    style: TextStyle(
                                      color: typeColor(m['type']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (canEdit) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                    onPressed: () => _confirmDeleteMovement(m),
                                    tooltip: 'Eliminar movimiento',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openMovementForm,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
