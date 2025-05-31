import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = '読み込み中...';
  List<Map<String, dynamic>> curriculums = []; // 追加

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadCurriculums(); // 追加
  }

  void _loadUsername() async {
    final tokens = await TokenStorage.getTokens();
    final accessToken = tokens['access'];
    if (accessToken == null) {
      setState(() {
        username = 'アクセストークンが見つかりません';
      });
      return;
    }

    final fetchedUsername = await AuthService.fetchUsername();
    setState(() {
      username = fetchedUsername ?? 'ユーザ名の取得に失敗しました';
    });
  }

  void _loadCurriculums() async {
    try {
      final result = await AuthService.fetchCurriculums();
      setState(() {
        curriculums = result;
      });
    } catch (e) {
      print('カリキュラム取得失敗: $e');
    }
  }

  Widget buildCurriculumCard(Map<String, dynamic> curriculum) {
    String name = curriculum['name'];
    double progress = (curriculum['progress'] ?? 0).toDouble();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(name, style: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.normal, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text('進捗: ${(progress).toStringAsFixed(1)}%', style: TextStyle(fontFamily: 'NotoSansJP', fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress/100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'ようこそ、$username さん！',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Expanded(
              child: curriculums.isEmpty
                  ? Center(child: Text('学習を始める'))
                  : ListView.builder(
                      itemCount: curriculums.length,
                      itemBuilder: (context, index) =>
                          buildCurriculumCard(curriculums[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
