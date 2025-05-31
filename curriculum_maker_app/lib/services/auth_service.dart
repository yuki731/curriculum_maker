// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';


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

    final data = _processResponse(response);

    // トークンがレスポンスに含まれていれば保存
    if (data.containsKey('access')) {
        String newAccess = data['access'];
        await TokenStorage.saveTokens(newAccess, refreshToken);
    }

    return data;
    }

  static Map<String, dynamic> _processResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'data': data};
    }
  }

static Future<String?> fetchUsername() async {
  final tokens = await TokenStorage.getTokens();
  String? accessToken = tokens['access'];
  final refreshToken = tokens['refresh'];

  Future<String?> _doRequest(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/home/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['username'];
    } else if (response.statusCode == 401 && refreshToken != null) {
      final refreshed = await refresh(refreshToken);
      final newAccess = refreshed['access'];
      if (newAccess != null) {
        return _doRequest(newAccess); // retry
      }
    }

    print('Failed to fetch username. Status: ${response.statusCode}');
    return null;
  }

  if (accessToken == null) throw Exception('Access token is missing');
  return await _doRequest(accessToken);
}

static Future<List<Map<String, dynamic>>> fetchCurriculums() async {
  final tokens = await TokenStorage.getTokens();
  String? accessToken = tokens['access'];
  final refreshToken = tokens['refresh'];

  Future<List<Map<String, dynamic>>> _doRequest(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/curriculum/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is List) {
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception('Unexpected response format: ${response.body}');
      }
    } else if (response.statusCode == 401 && refreshToken != null) {
      final refreshed = await refresh(refreshToken);
      final newAccess = refreshed['access'];
      if (newAccess != null) {
        return _doRequest(newAccess); // retry
      }
    }

    throw Exception('Failed to load curriculums: ${response.statusCode} ${response.body}');
  }

  if (accessToken == null) throw Exception('Access token is missing');
  return await _doRequest(accessToken);
}

}
