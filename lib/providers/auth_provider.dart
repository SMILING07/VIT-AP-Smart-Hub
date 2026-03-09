import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/vtop_api_service.dart';

class AuthProvider extends ChangeNotifier {
  final VtopApiService _apiService = VtopApiService();
  final _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    final regNo = await _secureStorage.read(key: 'regNo');
    if (regNo != null && regNo.isNotEmpty) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<void> login(String regNo, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool success = false;

      // Hardcoded admin bypass
      if (regNo.toLowerCase() == 'admin' && password == 'admin') {
        success = true;
      } else {
        success = await _apiService.login(regNo, password);
      }

      if (success) {
        _isAuthenticated = true;
        // Optionally save credentials (without password ideally, just session state)
        await _secureStorage.write(key: 'regNo', value: regNo);
      } else {
        _error = 'Login failed. Please check your credentials and captcha.';
      }
    } catch (e) {
      _error = 'Network error occurred. $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    await _secureStorage.delete(key: 'regNo');
    // Call api to invalidate session
    notifyListeners();
  }
}
