import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String _role = 'user';
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  String get role => _role;
  String? get lastError => _lastError;

  Future<void> checkToken() async {
    final token = await ApiService.getToken();
    if (token != null) {
      _isAuthenticated = true;
      // Ideally we would decode JWT or fetch user profile here
      // For now, assume simple auth
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final result = await ApiService.login(username, password);
      if (result['success']) {
        _isAuthenticated = true;
        _role = result['data']['role'] ?? 'user';
        _lastError = null;
        notifyListeners();
        return true;
      }

      _lastError = result['message']?.toString() ?? 'Login failed.';
      notifyListeners();
      return false;
    } catch (_) {
      _lastError = 'Unexpected error during login.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    final result = await ApiService.register(username, password);
    return result['success'];
  }

  Future<void> logout() async {
    await ApiService.removeToken();
    _isAuthenticated = false;
    _role = 'user';
    notifyListeners();
  }
}
