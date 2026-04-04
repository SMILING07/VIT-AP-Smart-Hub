import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  VtopApiService get apiService => _apiService;

  Future<void> checkAuthStatus() async {
    final regNo = await _secureStorage.read(key: 'regNo');
    final password = await _secureStorage.read(key: 'password');
    // final cookies = await _secureStorage.read(key: 'cookies');

    if (regNo != null && regNo.isNotEmpty && password != null) {
      // Perform a real login to establish the backend rust session
      await login(regNo, password);
    }
  }

  Future<String?> getActiveRegNo() async {
    return await _secureStorage.read(key: 'regNo');
  }

  Future<List<Map<String, String>>> getSavedAccounts() async {
    final str = await _secureStorage.read(key: 'saved_accounts');
    if (str == null) return [];
    try {
      final List dec = jsonDecode(str);
      return dec.map((e) => Map<String, String>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAccountToList(String regNo, String password) async {
    var accounts = await getSavedAccounts();
    accounts.removeWhere((acc) => acc['regNo'] == regNo);
    accounts.insert(0, {'regNo': regNo, 'password': password});
    await _secureStorage.write(
      key: 'saved_accounts',
      value: jsonEncode(accounts),
    );
  }

  Future<void> removeAccount(String regNo) async {
    var accounts = await getSavedAccounts();
    accounts.removeWhere((acc) => acc['regNo'] == regNo);
    await _secureStorage.write(
      key: 'saved_accounts',
      value: jsonEncode(accounts),
    );

    final activeRegNo = await _secureStorage.read(key: 'regNo');
    if (activeRegNo == regNo) {
      await logout();
    } else {
      notifyListeners();
    }
  }

  Future<void> login(String regNo, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool success = false;

      // Hardcoded admin bypass - keeping for compatibility during migration
      if (regNo.toLowerCase() == 'admin' && password == 'admin') {
        success = true;
      } else {
        success = await _apiService.login(regNo, password);
      }

      if (success) {
        _isAuthenticated = true;
        await _secureStorage.write(key: 'regNo', value: regNo);
        await _secureStorage.write(key: 'password', value: password);
        await _saveAccountToList(regNo, password);

        // Optionally fetch and save cookies for session persistence across cold starts
        // final cookies = await _apiService.getCookies();
        // if (cookies != null) {
        //   await _secureStorage.write(key: 'cookies', value: String.fromCharCodes(cookies));
        // }
      } else {
        _error = 'Login failed. Please check your credentials and captcha.';
      }
    } catch (e) {
      _error = 'Network error occurred. $e';
      debugPrint('Login Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    await _secureStorage.delete(key: 'regNo');
    await _secureStorage.delete(key: 'password');
    // await _secureStorage.delete(key: 'cookies');
    notifyListeners();
  }
}
