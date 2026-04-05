import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/cache_service.dart';
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

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  VtopApiService get apiService => _apiService;

  String? _activeRegNo;
  String? get activeRegNoSync => _activeRegNo;

  int _failedAttempts = 0;
  int get failedAttempts => _failedAttempts;

  String? _lastAttemptRegNo;

  bool _isNetworkError = false;
  bool get isNetworkError => _isNetworkError;

  Future<void> checkAuthStatus() async {
    try {
      final regNo = await _secureStorage.read(key: 'regNo');
      final password = await _secureStorage.read(key: 'password');

      if (regNo != null &&
          regNo.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        _activeRegNo = regNo;
        // Optimistically set authenticated if we have credentials
        // The VtopDataProvider will try to fetch using these
        _isAuthenticated = true;

        // However, we still need the backend to initialize the session
        // so we perform a "Silent Login"
        await login(regNo, password, isSilent: true);
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
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

  Future<void> login(
    String regNo,
    String password, {
    bool isSilent = false,
  }) async {
    if (!isSilent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      bool success = false;
      _isNetworkError = false;

      // Single source of truth: VTOP login
      success = await _apiService.login(regNo, password);

      if (success) {
        _isAuthenticated = true;
        _activeRegNo = regNo;
        _failedAttempts = 0;
        _lastAttemptRegNo = null;
        await _secureStorage.write(key: 'regNo', value: regNo);
        await _secureStorage.write(key: 'password', value: password);
        await _saveAccountToList(regNo, password);
      } else {
        if (_lastAttemptRegNo == regNo) {
          _failedAttempts++;
        } else {
          _lastAttemptRegNo = regNo;
          _failedAttempts = 1;
        }
        _error =
            'Invalid credentials. Please check your Registration Number and Password.';
      }
    } catch (e) {
      _isNetworkError = true;
      _error = 'No internet connection. Please check your network settings.';
      debugPrint('Login Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _activeRegNo = null;
    final oldRegNo = await _secureStorage.read(key: 'regNo');
    await _secureStorage.delete(key: 'regNo');
    await _secureStorage.delete(key: 'password');
    if (oldRegNo != null) {
      await CacheService.clearCache(oldRegNo);
    }
    notifyListeners();
  }
}
