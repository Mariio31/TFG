import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://10.0.2.2:8000';

class ApiService {
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
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // AUTH
  static Future<bool> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await saveToken(data['access_token']);
      return true;
    }
    return false;
  }

  // PRODUCTOS
  static Future<List<dynamic>> getProducts() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/products/'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> createProduct(Map<String, dynamic> data) async {
    final headers = await getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/products/'),
      headers: headers,
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteProduct(int id) async {
    final headers = await getHeaders();
    final res = await http.delete(Uri.parse('$baseUrl/products/$id'), headers: headers);
    return res.statusCode == 200;
  }

  // CATEGORIAS
  static Future<List<dynamic>> getCategories() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/categories/'), headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // MOVIMIENTOS
  static Future<List<dynamic>> getMovements() async {
    final headers = await getHeaders();
    final res = await http.get(Uri.parse('$baseUrl/movements/'), headers: headers);
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
    return res.statusCode == 200;
  }
}