import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Cambia a true para usar local, false para usar AWS
const bool useLocalBackend = false;

const String baseUrl = useLocalBackend 
    ? 'http://127.0.0.1:8000'
    : 'http://44.223.138.164';

class ApiService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _redirectingToLogin = false;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await clearUserSession();
  }

  static Future<void> saveUserSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user['id'] as int);
    await prefs.setString('user_role', user['role']?.toString() ?? 'employee');
    await prefs.setString('user_name', user['name']?.toString() ?? '');
    await prefs.setString('user_email', user['email']?.toString() ?? '');
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  static Future<bool> isManager() async {
    final role = await getUserRole();
    return role == 'manager';
  }

  /// Admin o manager: crear y editar productos, categorías y movimientos.
  static Future<bool> canEdit() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'manager';
  }

  /// Solo admin: eliminar productos y categorías.
  static Future<bool> canDelete() async {
    return isAdmin();
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> handleUnauthorized(int statusCode) async {
    if (statusCode != 401 || _redirectingToLogin) return;

    _redirectingToLogin = true;
    await removeToken();

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/', (route) => false);
    }

    _redirectingToLogin = false;
  }

  // AUTH
  static Future<bool> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await saveToken(data['access_token']);
      final user = await getCurrentUser();
      if (user != null) {
        await saveUserSession(user);
      }
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: headers);
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    }
    return null;
  }

  // USUARIOS (solo admin)
  static Future<List<dynamic>> getUsers() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/users/'), headers: headers);
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> createUser(Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  static Future<String?> deleteUser(int id) async {
    final headers = await getHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers,
    );
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) return null;
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['detail'] != null) {
        return body['detail'].toString();
      }
    } catch (_) {}
    return 'No se pudo eliminar el usuario';
  }

  static Future<bool> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // PRODUCTOS
  static Future<List<dynamic>> getProducts({int? skip, int? limit}) async {
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/products/').replace(
      queryParameters: {
        if (skip != null) 'skip': skip.toString(),
        if (limit != null) 'limit': limit.toString(),
      },
    );
    final res = await http.get(uri, headers: headers);
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<Map<String, dynamic>?> createProductAndReturn(
    Map<String, dynamic> data,
  ) async {
    final headers = await getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/products/'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  static Future<bool> createProduct(Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/products/'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  static Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  static Future<bool> deleteProduct(int id) async {
    final headers = await getHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: headers,
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  // IMAGENES DE PRODUCTOS
  static Future<bool> uploadProductImage(int productId, String filePath) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/products/$productId/image');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final ext = filePath.split('.').last.toLowerCase();
    final mimeSubtype = ext == 'jpg' ? 'jpeg' : ext; // jpg -> jpeg

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType('image', mimeSubtype),
      ),
    );

    final response = await request.send();
    await handleUnauthorized(response.statusCode);
    return response.statusCode == 200;
  }

  static String getProductImageUrl(int productId) {
    return '$baseUrl/products/$productId/image';
  }

  static Future<bool> deleteProductImage(int productId) async {
    final headers = await getHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$productId/image'),
      headers: headers,
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  // CATEGORIAS
  static Future<List<dynamic>> getCategories() async {
    final headers = await getHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/categories/'),
      headers: headers,
    );
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> createCategory(Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/categories/'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  static Future<bool> updateCategory(int id, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  static Future<bool> deleteCategory(int id) async {
    final headers = await getHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  // MOVIMIENTOS
  static Future<List<dynamic>> getMovements({int? skip, int? limit}) async {
    final headers = await getHeaders();
    final uri = Uri.parse('$baseUrl/movements/').replace(
      queryParameters: {
        if (skip != null) 'skip': skip.toString(),
        if (limit != null) 'limit': limit.toString(),
      },
    );
    final res = await http.get(uri, headers: headers);
    await handleUnauthorized(res.statusCode);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> createMovement(Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/movements/'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  static Future<bool> updateMovement(int id, Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.put(
      Uri.parse('$baseUrl/movements/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }

  static Future<bool> deleteMovement(int id) async {
    final headers = await getHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/movements/$id'),
      headers: headers,
    );
    await handleUnauthorized(res.statusCode);
    return res.statusCode == 200;
  }
}
