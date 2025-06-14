import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
  List<Map<String, dynamic>>? _curriculums;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final message = _messageController.text;
    final period = _periodController.text;

    setState(() => _loading = true);

    try {
      final result = await AuthService.createCurriculums(message, period);
      setState(() => _curriculums = result);
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            labelText: '学びたい内容（例: Flutterを学びたい）',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? '入力してください' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _periodController,
                          decoration: const InputDecoration(
                            labelText: '学習時間の目安（例: 8時間）',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? '入力してください' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submit,
                          child: const Text('カリキュラムを生成する'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_curriculums != null)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _curriculums!.length,
                        itemBuilder: (context, index) {
                          final item = _curriculums![index];
                          return Card(
                            child: ListTile(
                              title: Text(item['title'] ?? 'No Title'),
                              subtitle: Text(item['content'] ?? ''),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
