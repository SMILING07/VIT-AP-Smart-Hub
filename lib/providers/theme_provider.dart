import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> _loadThemeMode() async {
    try {
      final savedMode = await _secureStorage.read(key: _themeModeKey);
      if (savedMode != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.name == savedMode,
          orElse: () => ThemeMode.dark,
        );
        notifyListeners();
      }
    } catch (e) {
      // Fallback to system if something goes wrong reading storage
      debugPrint('Error loading theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      await _secureStorage.write(key: _themeModeKey, value: mode.name);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }
}
