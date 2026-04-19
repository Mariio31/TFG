class Product {
  final int id;
  final String name;
  final String? sku;
  final String? description;
  final double price;
  final double cost;
  final int stock;
  final int minStock;
  final String unit;
  final String? supplier;

  Product({
    required this.id,
    required this.name,
    this.sku,
    this.description,
    required this.price,
    required this.cost,
    required this.stock,
    required this.minStock,
    required this.unit,
    this.supplier,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      minStock: json['min_stock'] ?? 5,
      unit: json['unit'] ?? 'unidad',
      supplier: json['supplier'],
    );
  }
}