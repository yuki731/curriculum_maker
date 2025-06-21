import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import 'curriculum_detail_page.dart';
import 'curriculum_info_page.dart';


class CurriculumInputPage extends StatefulWidget {
  const CurriculumInputPage({super.key});

  @override
  State<CurriculumInputPage> createState() => _CurriculumInputPageState();
}

class _CurriculumInputPageState extends State<CurriculumInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _periodController = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _curriculums;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final message = _messageController.text;
    final period = _periodController.text;

    setState(() => _loading = true);

    try {
      final curriculum = await AuthService.createCurriculums(message, period);
      setState(() => _curriculums = curriculum);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CurriculumInfoPage(curriculum: curriculum),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カリキュラム生成')),
      body: Stack(                                    // ← ここを Stack に
        children: [
          Padding(                                    // フォーム本体
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: '学びたい内容（例: Flutter）',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? '入力必須' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _periodController,
                    decoration: const InputDecoration(
                      labelText: '学習時間（例: 8時間）',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? '入力必須' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit, // 多重送信防止
                    child: const Text('カリキュラムを生成する'),
                  ),
                ],
              ),
            ),
          ),

          // ④ ローディングレイヤー（_loading が true の間だけ表示）
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,                // 半透明オーバーレイ
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/loading.json',
                        width: 500,
                        height: 500,
                        repeat: true,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'AI がカリキュラムを生成しています…',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}