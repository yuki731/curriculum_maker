// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/token_storage.dart';

// const baseUrl = "http://127.0.0.1:8000";
// const baseUrl2 = "http://127.0.0.1:7000";

const baseUrl = "https://www.curriculummaker.dev/api";
const baseUrl2 = "https://www.curriculummaker.dev/agent";

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

static Future<List<Map<String, dynamic>>> fetchMoviesByCurriculumId(int id) async {
  final tokens = await TokenStorage.getTokens();
  String? accessToken = tokens['access'];
  final refreshToken = tokens['refresh'];

  Future<List<Map<String, dynamic>>> _doRequest(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$id/'),
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

    throw Exception('Failed to load movies: ${response.statusCode} ${response.body}');
  }

  if (accessToken == null) throw Exception('Access token is missing');
  return await _doRequest(accessToken);
}

static Future<Map<String, dynamic>> createCurriculums(
    String message, String period) async {
  final tokens = await TokenStorage.getTokens();
  String? accessToken = tokens['access'];
  final refreshToken = tokens['refresh'];

  // ❶ 戻り値を Map 固定に
  Future<Map<String, dynamic>> _doRequest(String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl2/gen/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'period': period,
        'accessToken': accessToken,
        'refreshToken': refreshToken
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      // ❷ API が Map を返す想定
      if (data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data);
      }

      // もし List がくるケースも一応ハンドリング
      if (data is List && data.isNotEmpty && data.first is Map) {
        return Map<String, dynamic>.from(data.first);
      }

      throw Exception('Unexpected response format: ${response.body}');
    }

    // 401 → リフレッシュして再試行
    if (response.statusCode == 401 && refreshToken != null) {
      final refreshed = await refresh(refreshToken);
      final newAccess = refreshed['access'];
      if (newAccess != null) {
        return _doRequest(newAccess); // retry with new token
      }
    }

    throw Exception(
        'Failed to load curriculum: ${response.statusCode} ${response.body}');
  }

  if (accessToken == null) {
    throw Exception('Access token is missing');
  }

  // ❸ 呼び出し部も Map 固定
  return await _doRequest(accessToken);
}


static Future<List<Map<String, dynamic>>> updateMovieStatus(int curriculumId, int movieId, bool status, double rating) async {
  final tokens = await TokenStorage.getTokens();
  String? accessToken = tokens['access'];
  final refreshToken = tokens['refresh'];

  Future<List<Map<String, dynamic>>> _doRequest(String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/movie/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'curriculum_id': curriculumId, 'movie_id': movieId, 'status': status, 'rating': rating}),
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      // 成功時は何らかのリストを返す（空でも良い）
      return []; // or [{'status': 'ok'}] など、呼び出し側に合わせて調整
    }

    if (response.statusCode == 401 && refreshToken != null) {
      final refreshed = await refresh(refreshToken);
      final newAccess = refreshed['access'];
      if (newAccess != null) {
        return _doRequest(newAccess); // retry
      }
    }

    throw Exception('Failed to update movie status: ${response.statusCode} ${response.body}');
  }

  if (accessToken == null) throw Exception('Access token is missing');
  return await _doRequest(accessToken);
}

  static Future<List<Map<String, dynamic>>> fetchQuizzes(int movieId) async {
    // 1) トークン取得
    final tokens = await TokenStorage.getTokens(); // { access: ..., refresh: ... }
    String? accessToken = tokens['access'];
    final refreshToken = tokens['refresh'];

    // 2) 内部リクエスト関数
    Future<List<Map<String, dynamic>>> _doRequest(String accessToken) async {
      final uri = Uri.parse('$baseUrl/quiz/')           // ← エンドポイント名は要調整
          .replace(queryParameters: {'movie_id': movieId.toString()});

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 60)); // ネットワークタイムアウト任意

      // ----- 成功 -----
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // {movie: "...", questions: [...] } を想定
        if (data is Map && data['questions'] is List) {
          return List<Map<String, dynamic>>.from(data['questions']);
        }
        throw Exception('Unexpected response format: ${response.body}');
      }

      // ----- アクセストークン失効 → リフレッシュ -----
      if (response.statusCode == 401 && refreshToken != null) {
        final refreshed = await refresh(refreshToken); // {access: "...", refresh: "..."}
        final newAccess = refreshed['access'];
        if (newAccess != null) {
          return _doRequest(newAccess); // 再試行
        }
      }

      // ----- それ以外はエラー -----
      throw Exception(
        'Failed to load quizzes: ${response.statusCode} ${response.body}',
      );
    }

    if (accessToken == null) throw Exception('Access token is missing');
    return _doRequest(accessToken);
  }

}
