// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = "http://127.0.0.1:8000"; // ← ここは実際のAPI URLに変更

class AuthService {
  static Future<Map<String, dynamic>> signup(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );
    return _processResponse(response);
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'data': data};
    }
  }

  static Future<String?> fetchUsername(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/home/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['username'];
    } else {
      print('Failed to fetch username. Status: ${response.statusCode}');
      return null;
    }
  }
}
