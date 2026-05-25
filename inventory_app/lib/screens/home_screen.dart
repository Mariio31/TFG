import 'package:flutter/material.dart';
import 'package:inventory_app/services/api_service.dart';
import 'package:inventory_app/screens/dashboard_screen.dart';
import 'package:inventory_app/screens/products_screen.dart';
import 'package:inventory_app/screens/movements_screen.dart';
import 'package:inventory_app/screens/categories_screen.dart';
import 'package:inventory_app/screens/users_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  bool isAdmin = false;
  int _productsScreenKey = 0;
  bool _productsLowStockFilter = false;

  void _navigateToProducts() {
    setState(() {
      currentIndex = 1;
      _productsLowStockFilter = false;
      _productsScreenKey++;
    });
  }

  void _navigateToCategories() {
    setState(() => currentIndex = 3);
  }

  void _navigateToMovements() {
    setState(() => currentIndex = 2);
  }

  void _navigateToProductsLowStock() {
    setState(() {
      currentIndex = 1;
      _productsLowStockFilter = true;
      _productsScreenKey++;
    });
  }

  void _goToMenu() {
    setState(() {
      currentIndex = 0;
      _productsLowStockFilter = false;
    });
  }

  List<Widget> get _screens => [
        DashboardScreen(
          onNavigateToProducts: _navigateToProducts,
          onNavigateToCategories: _navigateToCategories,
          onNavigateToMovements: _navigateToMovements,
          onNavigateToProductsLowStock: _navigateToProductsLowStock,
        ),
        ProductsScreen(
          key: ValueKey('products_$_productsScreenKey'),
          initialLowStockFilter: _productsLowStockFilter,
          onBackToMenu: _goToMenu,
        ),
        MovementsScreen(onBackToMenu: _goToMenu),
        CategoriesScreen(onBackToMenu: _goToMenu),
      ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final admin = await ApiService.isAdmin();
    if (mounted) setState(() => isAdmin = admin);
  }

  Future<void> handleLogout() async {
    await ApiService.removeToken();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Inventory App'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Gestión de usuarios',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersScreen()),
                );
                _loadRole();
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: handleLogout,
          ),
        ],
      ),
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (i) => setState(() {
          currentIndex = i;
          if (i != 1) _productsLowStockFilter = false;
        }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Productos'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Movimientos'),
          BottomNavigationBarItem(icon: Icon(Icons.label), label: 'Categorías'),
        ],
      ),
    );
  }
}