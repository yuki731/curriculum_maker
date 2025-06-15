import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CurriculumInfoPage extends StatelessWidget {
  final Map<String, dynamic> curriculum;

  const CurriculumInfoPage({Key? key, required this.curriculum}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String markdown = curriculum['detail'] ?? '_詳細なし_';

    return Scaffold(
      appBar: AppBar(
        title: const Text('カリキュラム詳細'),
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
