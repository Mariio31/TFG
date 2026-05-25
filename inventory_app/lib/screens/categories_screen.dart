import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/utils/confirm_dialogs.dart';
import 'package:inventory_app/widgets/back_leading.dart';
import 'package:inventory_app/screens/products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final VoidCallback? onBackToMenu;
  const CategoriesScreen({super.key, this.onBackToMenu});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> categories = [];
  bool loading = true;
  bool canEdit = false;
  bool canDelete = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    loadCategories();
  }

  Future<void> _loadPermissions() async {
    final edit = await ApiService.canEdit();
    final del = await ApiService.canDelete();
    if (mounted) {
      setState(() {
        canEdit = edit;
        canDelete = del;
      });
    }
  }

  Future<void> loadCategories() async {
    setState(() => loading = true);
    final data = await ApiService.getCategories();
    setState(() {
      categories = data;
      loading = false;
    });
  }

  Future<void> handleDelete(int id, String name) async {
    final confirmed = await confirmDelete(context);
    if (!confirmed) return;
    await ApiService.deleteCategory(id);
    await loadCategories();
  }

  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.blue;
    if (colorValue is String) {
      try {
        return Color(int.parse(colorValue.replaceFirst('#', ''), radix: 16) | 0xFF000000);
      } catch (_) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Future<void> openCategoryForm([Map<String, dynamic>? category]) async {
    final isEditing = category != null;
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descriptionController = TextEditingController(text: category?['description'] ?? '');
    Color selectedColor = _parseColor(category?['color']);
    final colorController = TextEditingController(text: _colorToHex(selectedColor));

    final initialName = nameController.text;
    final initialDescription = descriptionController.text;
    final initialColorHex = _colorToHex(selectedColor);

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
              if (!isEditing) return false;
              if (nameController.text.trim() != initialName.trim()) return true;
              if (descriptionController.text.trim() != initialDescription.trim()) {
                return true;
              }
              if (_colorToHex(selectedColor) != initialColorHex) return true;
              return false;
            }

            return FormDiscardPopScope(
              isEditMode: isEditing,
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
                          isEditing ? 'Editar categoría' : 'Crear categoría',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => closeFormSheet(
                            context,
                            isEditMode: isEditing,
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
                            controller: descriptionController,
                            decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: colorController,
                                  decoration: const InputDecoration(
                                    labelText: 'Color (Hex)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setModalState(() {
                                      try {
                                        selectedColor = Color(int.parse(value.replaceFirst('#', ''), radix: 16) | 0xFF000000);
                                      } catch (_) {}
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () async {
                                  final color = await showDialog<Color>(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: GridView.count(
                                              crossAxisCount: 4,
                                              shrinkWrap: true,
                                              children: [
                                                Colors.blue,
                                                Colors.red,
                                                Colors.green,
                                                Colors.orange,
                                                Colors.purple,
                                                Colors.pink,
                                                Colors.cyan,
                                                Colors.amber,
                                                Colors.indigo,
                                                Colors.lime,
                                                Colors.teal,
                                                Colors.grey,
                                              ]
                                                  .map(
                                                    (color) => GestureDetector(
                                                      onTap: () => Navigator.pop(context, color),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: color,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (color != null) {
                                    setModalState(() {
                                      selectedColor = color;
                                      colorController.text = _colorToHex(color);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: selectedColor,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState?.validate() != true) return;
                              if (isEditing) {
                                final confirmed = await confirmSaveChanges(context);
                                if (!confirmed) return;
                              }
                              final data = <String, dynamic>{
                                'name': nameController.text.trim(),
                                'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                                'color': _colorToHex(selectedColor),
                              }..removeWhere((key, value) => value == null);

                              final success = isEditing
                                  ? await ApiService.updateCategory(category!['id'], data)
                                  : await ApiService.createCategory(data);

                              if (!mounted) return;
                              if (success) {
                                Navigator.of(context).pop();
                                await loadCategories();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isEditing ? 'Categoría actualizada' : 'Categoría creada')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error al guardar la categoría')),
                                );
                              }
                            },
                            child: Text(isEditing ? 'Guardar cambios' : 'Crear categoría'),
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
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: buildBackLeading(context, onBackToMenu: widget.onBackToMenu),
        automaticallyImplyLeading: false,
        title: const Text('Categorías'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadCategories,
        child: categories.isEmpty
            ? const Center(child: Text('No hay categorías aún'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];
                  final color = _parseColor(c['color']);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductsScreen(
                              initialCategoryId: c['id'] as int?,
                            ),
                          ),
                        );
                      },
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      title: Text(c['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['description'] ?? 'Sin descripción'),
                          const SizedBox(height: 4),
                          Text(
                            '${c['product_count'] ?? 0} producto${(c['product_count'] ?? 0) == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      trailing: (canEdit || canDelete)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canEdit)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => openCategoryForm(c),
                                  ),
                                if (canDelete)
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red.shade700),
                                    onPressed: () => handleDelete(c['id'], c['name']),
                                  ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => openCategoryForm(),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
