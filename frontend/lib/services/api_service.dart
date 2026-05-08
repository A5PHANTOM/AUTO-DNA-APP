import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Manual LAN URL for physical Android testing.
  // Replace the IP when your Mac changes networks.
  static const String baseUrl = 'http://192.168.1.2:8000/api';

  // All requests must include this header or localtunnel returns an HTML warning page
  static const Map<String, String> _tunnelHeaders = {
    'bypass-tunnel-reminder': 'true',
  };

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> setToken(String token, {String role = 'user', int userId = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);
    await prefs.setInt('user_id', userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          ..._tunnelHeaders,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setToken(data['access_token'], role: data['role'] ?? 'user', userId: data['user_id'] ?? 0);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Invalid credentials (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot reach server: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(String username, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          ..._tunnelHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode({'username': username, 'password': password, 'role': role}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Registration failed. Username may exist.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: Cannot reach backend server.'};
    }
  }

  // Other endpoints handles will be added here
}
