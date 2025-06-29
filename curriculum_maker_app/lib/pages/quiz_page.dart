import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // QuizApi, TokenStorage などを含む

/// ---------------------------------------------------------
/// QuizPage – 1 問ずつ表示し、カードタップで正誤判定
/// ---------------------------------------------------------
class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.movieId});

  final int movieId;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<List<Map<String, dynamic>>> _future;
  int _current = 0;
  int _correctCount = 0;
  int? _selectedIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _future = AuthService.fetchQuizzes(widget.movieId);
  }

  void _onSelect(int idx, bool isCorrect) {
    if (_answered) return;
    setState(() {
      _selectedIndex = idx;
      _answered = true;
      if (isCorrect) _correctCount++;
    });
  }

  void _next() {
    setState(() {
      _current++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final quizzes = snapshot.data!;

          if (_current >= quizzes.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('終了！', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Text('正解数 $_correctCount / ${quizzes.length}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            );
          }

          final q = quizzes[_current];
          final choices = List<Map<String, dynamic>>.from(q['choices']);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text('問題 ${_current + 1}/${quizzes.length}',
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(q['prompt'], style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                ...List.generate(choices.length, (idx) {
                  final choice = choices[idx];
                  final isCorrect = choice['is_correct'] as bool;
                  Color? color;
                  if (_answered) {
                    if (idx == _selectedIndex) {
                      color = isCorrect ? Colors.green : Colors.red;
                    } else if (isCorrect) {
                      color = Colors.green.withOpacity(0.4);
                    }
                  }
                  return Card(
                    color: color,
                    child: InkWell(
                      onTap: () => _onSelect(idx, isCorrect),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(choice['text']),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                if (_answered)
                  ElevatedButton(
                    onPressed: _next,
                    child: const Text('次の問題へ'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
