import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'curriculum_detail_page.dart'; // ← これがなければ追加！

class CurriculumInfoPage extends StatelessWidget {
  final Map<String, dynamic> curriculum;

  const CurriculumInfoPage({super.key, required this.curriculum});

  void _handleNavigate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumDetailPage(curriculum: curriculum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String markdown = curriculum['detail'] ?? '_詳細なし_';

    return Scaffold(
      appBar: AppBar(
        title: Text(curriculum['name'] ?? 'カリキュラム詳細'),
        actions: [
          TextButton(
            onPressed: () => _handleNavigate(context),
            child: const Text(
              'さっそく学習を始める',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(
          data: markdown,
          selectable: true,
        ),
      ),
    );
  }
}
