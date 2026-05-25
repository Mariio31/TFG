import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/utils/confirm_dialogs.dart';
import 'package:inventory_app/widgets/back_leading.dart';

class ProductsScreen extends StatefulWidget {
  final int? initialCategoryId;
  final bool initialLowStockFilter;
  final VoidCallback? onBackToMenu;
  const ProductsScreen({
    super.key,
    this.initialCategoryId,
    this.initialLowStockFilter = false,
    this.onBackToMenu,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const int _pageSize = 20;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> categories = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMoreProducts = true;
  bool loadingCategories = true;
  bool canEdit = false;
  bool canDelete = false;
  String currentFilter = 'Todos';
  int? selectedCategoryId;
  String unifiedFilter = 'Todas';

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
    _loadPermissions();
    selectedCategoryId = widget.initialCategoryId;
    if (selectedCategoryId != null) {
      unifiedFilter = 'cat_$selectedCategoryId';
    } else if (widget.initialLowStockFilter) {
      unifiedFilter = 'Stock bajo';
      currentFilter = 'Stock bajo';
    }
    loadProducts();
    loadCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        loading ||
        loadingMore ||
        !hasMoreProducts) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      loadMoreProducts();
    }
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
    final data = await ApiService.getCategories();
    setState(() {
      categories = data;
      loadingCategories = false;
    });
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    final data = await ApiService.getProducts(skip: 0, limit: _pageSize);
    setState(() {
      products = data;
      hasMoreProducts = data.length == _pageSize;
      loadingMore = false;
      loading = false;
    });
    filterProducts(searchController.text);
  }

  Future<void> loadMoreProducts() async {
    setState(() => loadingMore = true);
    final data = await ApiService.getProducts(
      skip: products.length,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      products.addAll(data);
      hasMoreProducts = data.length == _pageSize;
      loadingMore = false;
    });
    filterProducts(searchController.text);
  }

  void filterProducts(String query) {
    final lower = query.toLowerCase();
    setState(() {
      filteredProducts = products.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final sku = (item['sku'] ?? '').toString().toLowerCase();
        final matchesQuery = name.contains(lower) || sku.contains(lower);

        // Filtro por categoría
        if (selectedCategoryId != null) {
          final itemCategoryId =
              int.tryParse(item['category_id']?.toString() ?? '-1') ?? -1;
          if (itemCategoryId != selectedCategoryId) return false;
        }

        // Filtro por stock bajo
        if (currentFilter == 'Stock bajo') {
          final stock = int.tryParse(item['stock']?.toString() ?? '0') ?? 0;
          final minStock =
              int.tryParse(item['min_stock']?.toString() ?? '0') ?? 0;
          if (stock > minStock) return false;
        }

        return matchesQuery;
      }).toList();
    });
  }

  void applyUnifiedFilter(String? value) {
    if (value == null) return;
    setState(() {
      unifiedFilter = value;
      if (value == 'Todas') {
        currentFilter = 'Todos';
        selectedCategoryId = null;
      } else if (value == 'Stock bajo') {
        currentFilter = 'Stock bajo';
        selectedCategoryId = null;
      } else if (value.startsWith('cat_')) {
        currentFilter = 'Todos';
        selectedCategoryId = int.tryParse(value.split('_')[1]);
      }
    });
    filterProducts(searchController.text);
  }

  Future<void> handleDelete(int id) async {
    final confirmed = await confirmDelete(context);
    if (!confirmed) return;
    await ApiService.deleteProduct(id);
    await loadProducts();
  }

  Future<void> openProductForm([Map<String, dynamic>? product]) async {
    final isEditing = product != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final skuController = TextEditingController(text: product?['sku'] ?? '');
    final descriptionController = TextEditingController(
      text: product?['description'] ?? '',
    );
    final priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );
    final costController = TextEditingController(
      text: product?['cost']?.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: product?['stock']?.toString() ?? '',
    );
    final minStockController = TextEditingController(
      text: product?['min_stock']?.toString() ?? '',
    );
    final supplierController = TextEditingController(
      text: product?['supplier'] ?? '',
    );
    String unitValue = product?['unit']?.toString() ?? 'unidad';

    // Estado local para el dropdown de categorías
    List<dynamic> formCategories = categories;
    int? formCategoryId = product?['category_id'] != null
        ? int.tryParse(product!['category_id'].toString())
        : null;
    bool loadingFormCategories = categories.isEmpty;

    // Estado local para la imagen seleccionada
    XFile? pickedImage;
    bool imageDeleted = false; // si el usuario eliminó la imagen existente

    final initialName = nameController.text;
    final initialSku = skuController.text;
    final initialDescription = descriptionController.text;
    final initialPrice = priceController.text;
    final initialCost = costController.text;
    final initialStock = stockController.text;
    final initialMinStock = minStockController.text;
    final initialSupplier = supplierController.text;
    final initialUnit = unitValue;
    final initialCategoryId = formCategoryId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final ext = image.path.split('.').last.toLowerCase();
                if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Solo se permiten imágenes JPG, PNG o WEBP',
                      ),
                    ),
                  );
                  return;
                }
                setModalState(() {
                  pickedImage = image;
                  imageDeleted = false;
                });
              }
            }

            final bool hasExistingImage =
                isEditing && product?['image_path'] != null && !imageDeleted;
            final bool showImage = pickedImage != null || hasExistingImage;

            bool hasUnsavedChanges() {
              if (!isEditing) return false;
              if (pickedImage != null || imageDeleted) return true;
              if (nameController.text.trim() != initialName.trim()) return true;
              if (skuController.text.trim() != initialSku.trim()) return true;
              if (descriptionController.text.trim() !=
                  initialDescription.trim()) {
                return true;
              }
              if (priceController.text.trim() != initialPrice.trim())
                return true;
              if (costController.text.trim() != initialCost.trim()) return true;
              if (stockController.text.trim() != initialStock.trim())
                return true;
              if (minStockController.text.trim() != initialMinStock.trim())
                return true;
              if (supplierController.text.trim() != initialSupplier.trim())
                return true;
              if (unitValue != initialUnit) return true;
              if (formCategoryId != initialCategoryId) return true;
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
                            isEditing ? 'Editar producto' : 'Crear producto',
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
                      // ------- Selector de imagen -------
                      GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: pickedImage != null
                                    ? Image.file(
                                        File(pickedImage!.path),
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      )
                                    : hasExistingImage
                                    ? Image.network(
                                        ApiService.getProductImageUrl(
                                          product!['id'],
                                        ),
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) =>
                                            _imagePlaceholder(),
                                      )
                                    : _imagePlaceholder(),
                              ),
                            ),
                            // Botón de eliminar imagen (solo si hay imagen)
                            if (showImage)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () async {
                                      final confirmed = await confirmDelete(
                                        context,
                                      );
                                      if (!confirmed) return;
                                      if (hasExistingImage &&
                                          pickedImage == null) {
                                        await ApiService.deleteProductImage(
                                          product!['id'],
                                        );
                                      }
                                      setModalState(() {
                                        pickedImage = null;
                                        imageDeleted = true;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ------- Formulario -------
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                border: OutlineInputBorder(),
                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'SKU',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            loadingFormCategories
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : DropdownButtonFormField<int>(
                                    value: formCategoryId,
                                    decoration: const InputDecoration(
                                      labelText: 'Categoría',
                                      border: OutlineInputBorder(),
                                    ),
                                    hint: const Text(
                                      'Selecciona una categoría',
                                    ),
                                    items: formCategories
                                        .map(
                                          (cat) => DropdownMenuItem<int>(
                                            value:
                                                int.tryParse(
                                                  cat['id'].toString(),
                                                ) ??
                                                0,
                                            child: Text(
                                              cat['name']?.toString() ??
                                                  'Sin nombre',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setModalState(() {
                                        formCategoryId = value;
                                      });
                                    },
                                  ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: units.contains(unitValue)
                                  ? unitValue
                                  : 'unidad',
                              items: units
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  unitValue = value;
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: priceController,
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: costController,
                              decoration: const InputDecoration(
                                labelText: 'Coste',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: minStockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock mínimo',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: supplierController,
                              decoration: const InputDecoration(
                                labelText: 'Proveedor',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: () async {
                                if (formKey.currentState?.validate() != true)
                                  return;
                                if (isEditing) {
                                  final confirmed = await confirmSaveChanges(
                                    context,
                                  );
                                  if (!confirmed) return;
                                }
                                final data = <String, dynamic>{
                                  'name': nameController.text.trim(),
                                  'sku': skuController.text.trim().isEmpty
                                      ? null
                                      : skuController.text.trim(),
                                  'description':
                                      descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  'category_id': formCategoryId,
                                  'price': priceController.text.trim().isEmpty
                                      ? null
                                      : double.tryParse(
                                          priceController.text.trim(),
                                        ),
                                  'cost': costController.text.trim().isEmpty
                                      ? null
                                      : double.tryParse(
                                          costController.text.trim(),
                                        ),
                                  'stock': stockController.text.trim().isEmpty
                                      ? null
                                      : int.tryParse(
                                          stockController.text.trim(),
                                        ),
                                  'min_stock':
                                      minStockController.text.trim().isEmpty
                                      ? null
                                      : int.tryParse(
                                          minStockController.text.trim(),
                                        ),
                                  'unit': unitValue,
                                  'supplier':
                                      supplierController.text.trim().isEmpty
                                      ? null
                                      : supplierController.text.trim(),
                                }..removeWhere((key, value) => value == null);

                                int? productId;

                                if (isEditing) {
                                  productId = product!['id'];
                                  final success =
                                      await ApiService.updateProduct(
                                        productId!,
                                        data,
                                      );
                                  if (!context.mounted) return;
                                  if (!success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error al guardar el producto',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                } else {
                                  final created =
                                      await ApiService.createProductAndReturn(
                                        data,
                                      );
                                  if (!context.mounted) return;
                                  if (created == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Error al guardar el producto',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  productId = created['id'];
                                }

                                // Subir imagen si se seleccionó una
                                if (pickedImage != null && productId != null) {
                                  await ApiService.uploadProductImage(
                                    productId,
                                    pickedImage!.path,
                                  );
                                }

                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                await loadProducts();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'Producto actualizado'
                                          : 'Producto creado',
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                isEditing
                                    ? 'Guardar cambios'
                                    : 'Crear producto',
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

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Seleccionar imagen',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
        Text(
          'JPG, PNG o WEBP',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> showProductDetails(Map<String, dynamic> p) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // Buscar el nombre de la categoría
        final categoryId =
            int.tryParse(p['category_id']?.toString() ?? '-1') ?? -1;
        final categoryName =
            categories.firstWhere(
              (cat) => int.tryParse(cat['id'].toString()) == categoryId,
              orElse: () => null,
            )?['name'] ??
            'Sin categoría';

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p['name'] ?? 'Producto',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _detailRow('SKU', p['sku']?.toString() ?? '-'),
                _detailRow('Descripción', p['description']?.toString() ?? '-'),
                _detailRow('Categoría', categoryName),
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
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildProductLeading(Map<String, dynamic> p) {
    final stock = int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
    final minStock = int.tryParse(p['min_stock']?.toString() ?? '0') ?? 0;
    final lowStock = stock <= minStock;
    final hasImage =
        p['image_path'] != null && p['image_path'].toString().isNotEmpty;
    final productId = p['id'];

    Widget child;
    if (hasImage && productId != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Image.network(
            ApiService.getProductImageUrl(productId),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _stockCircle(stock, lowStock),
          ),
        ),
      );
    } else {
      child = _stockCircle(stock, lowStock);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          left: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: lowStock ? Colors.red : Colors.blue,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '$stock',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stockCircle(int stock, bool lowStock) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade600,
        size: 28,
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
        leading: buildBackLeading(context, onBackToMenu: widget.onBackToMenu),
        automaticallyImplyLeading: false,
        title: const Text('Productos'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
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
                        value: unifiedFilter,
                        icon: const Icon(Icons.filter_list),
                        onChanged: applyUnifiedFilter,
                        items: [
                          const DropdownMenuItem(
                            value: 'Todas',
                            child: Text('Todas'),
                          ),
                          const DropdownMenuItem(
                            value: 'Stock bajo',
                            child: Text('Stock bajo'),
                          ),
                          if (categories.isNotEmpty)
                            const DropdownMenuItem(
                              value: '',
                              enabled: false,
                              child: Divider(),
                            ),
                          ...categories.map(
                            (cat) => DropdownMenuItem(
                              value: 'cat_${cat['id']}',
                              child: Text(
                                cat['name']?.toString() ?? 'Sin nombre',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('No hay productos que coincidan'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      itemCount:
                          filteredProducts.length + (loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredProducts.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final p = filteredProducts[index];
                        final price =
                            double.tryParse(p['price']?.toString() ?? '0') ??
                            0.0;
                        final stock = int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
                        final minStock = int.tryParse(p['min_stock']?.toString() ?? '0') ?? 0;
                        final lowStock = stock <= minStock;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: lowStock
                                ? const BorderSide(color: Colors.red, width: 2)
                                : BorderSide.none,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            onTap: canEdit
                                ? () => openProductForm(p)
                                : () => showProductDetails(p),
                            onLongPress: canEdit
                                ? () => showProductDetails(p)
                                : null,
                            leading: _buildProductLeading(p),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p['name'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (lowStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Text(
                                      'Stock bajo',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SKU: ${p['sku'] ?? '-'}'),
                                const SizedBox(height: 4),
                                Text('Precio: ${price.toStringAsFixed(2)} €'),
                              ],
                            ),
                            trailing: canDelete
                                ? IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red.shade700,
                                    ),
                                    onPressed: () => handleDelete(p['id']),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => openProductForm(),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
