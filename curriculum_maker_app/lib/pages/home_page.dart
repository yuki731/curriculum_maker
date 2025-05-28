import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = '読み込み中...';

  @override
  void initState() {
    super.initState();
    _loadUsername();
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

    final fetchedUsername = await AuthService.fetchUsername(accessToken);
    setState(() {
      username = fetchedUsername ?? 'ユーザ名の取得に失敗しました';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Text(
          'ようこそ、$username さん！',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
