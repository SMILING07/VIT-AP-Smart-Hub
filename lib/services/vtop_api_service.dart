import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VtopApiService {
  static const String baseUrl = 'https://vtop.vitap.ac.in/vtop';

  // Store session cookies here
  Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// Attempts to login with Reg No and Password
  Future<bool> login(String regNo, String password) async {
    try {
      // Create the payload. This entirely depends on the forms actual fields
      // Common names might be 'uname', 'passwd'
      final Map<String, String> body = {
        'uname': regNo,
        'passwd': password,
        // include CSRF token if required by VTOP
      };

      final response = await http.post(
        Uri.parse('$baseUrl/vtopLogin'), // adjust endpoint if necessary
        headers: {
          ...headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      _updateCookies(response);

      // Simple heuristic for success: if we are redirected or if 'logout' exists in the body
      if (response.body.toLowerCase().contains('logout') ||
          response.statusCode == 302) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    }
  }

  void _updateCookies(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['Cookie'] = (index == -1)
          ? rawCookie
          : rawCookie.substring(0, index);
    }
  }
}
