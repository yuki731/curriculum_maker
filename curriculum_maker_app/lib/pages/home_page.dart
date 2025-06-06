import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import './curriculum_detail_page.dart'; // ← 新規追加（ファイル名に合わせて調整）

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = '読み込み中...';
  List<Map<String, dynamic>> curriculums = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadCurriculums();
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
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text('進捗: ${(progress).toStringAsFixed(1)}%'),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 10,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CurriculumDetailPage(curriculum: curriculum),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ongoing = curriculums.where((c) => c['status'] == false).toList();
    final completed = curriculums.where((c) => c['status'] == true).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'ようこそ、$username さん！',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),

            Text('📘 学習中のカリキュラム',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...ongoing.isEmpty
                ? [Text('現在、学習中のカリキュラムはありません')]
                : ongoing.map(buildCurriculumCard).toList(),

            SizedBox(height: 20),
            Text('✅ 学習済みのカリキュラム',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...completed.isEmpty
                ? [Text('まだ学習を完了したカリキュラムはありません')]
                : completed.map(buildCurriculumCard).toList(),
          ],
        ),
      ),
    );
  }
}
