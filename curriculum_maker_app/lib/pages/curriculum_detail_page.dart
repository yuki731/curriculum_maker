import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'curriculum_info_page.dart';
import 'home_page.dart';
import 'quiz_page.dart';

class CurriculumDetailPage extends StatefulWidget {
  final Map<String, dynamic> curriculum;

  CurriculumDetailPage({required this.curriculum, Key? key}) : super(key: key);

  @override
  _CurriculumDetailPageState createState() => _CurriculumDetailPageState();
}

class _CurriculumDetailPageState extends State<CurriculumDetailPage> {
  List<Map<String, dynamic>> movies = [];
  List<bool> isCheckedList = [];
  Map<String, YoutubePlayerController> controllers = {};


  Future<double?> _showRatingDialog() async {
    double tempRating = 3; // 初期値はお好みで
    return showDialog<double>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('動画のフィードバックをお願いします', style: TextStyle(fontSize: 18),),
            content: RatingBar.builder(
              initialRating: tempRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => const Icon(Icons.star, size: 32),
              onRatingUpdate: (rating) => setState(() => tempRating = rating),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), // キャンセル→null
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, tempRating), // 星数を返す
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  void _loadMovies() async {
    try {
      final result = await AuthService.fetchMoviesByCurriculumId(widget.curriculum['id']);
      final movieList = List<Map<String, dynamic>>.from(result);
      setState(() {
        movies = movieList;
        isCheckedList = movieList.map((movie) => movie['status'] == true).toList();
      });
      _initControllers();
    } catch (e) {
      print('カリキュラム取得失敗: $e');
    }
  }

  void _initControllers() {
    for (var movie in movies) {
      final videoId = YoutubePlayerController.convertUrlToId(movie['url']);
      if (videoId != null && !controllers.containsKey(videoId)) {
        controllers[videoId] = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const YoutubePlayerParams(showFullscreenButton: true),
        );
      }
    }
  }


  void _showYoutubeDialog(String videoId) {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final playerWidth = screenWidth * 0.9;
        final playerHeight = playerWidth * 9 / 16;

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: playerWidth,
            height: playerHeight,
            child: YoutubePlayerControllerProvider(
              controller: controller,
              child: YoutubePlayer(
                controller: controller,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("閉じる"),
              onPressed: () {
                controller.pauseVideo();
                Navigator.of(context).pop();
                controller.close();
              },
            )
          ],
        );
      },
    );
  }

  String? extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    }

    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }

    return null;
}

  Widget buildMovieCard(int index, Map<String, dynamic> movie) {
    String title = movie['title'] ?? 'タイトル不明';
    String url = movie['url'];
    final videoId = extractYoutubeId(url);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        // -----------------------------
        // ① タイトル行を Row で拡張
        // -----------------------------
        title: Row(
          children: [
            Expanded(child: Text(title)),

            // 確認問題リンク
            TextButton(
              onPressed: () {
                final movieId = movies[index]['id'] as int;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPage(movieId: movieId),
                  ),
                );
              },
              child: const Text(
                '確認問題',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),

        trailing: Checkbox(
          value: isCheckedList[index],
          onChanged: (bool? value) async {
            final newStatus = value ?? false;

            // 星いくつかを尋ねる
            final rating = await _showRatingDialog();
            if (rating == null) return; // キャンセル

            setState(() {
              isCheckedList[index] = newStatus;
            });

            try {
              await AuthService.updateMovieStatus(
                widget.curriculum['id'],
                movies[index]['id'],
                newStatus,
                rating,
              );
            } catch (e) {
              print('ステータス更新失敗: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ステータス更新に失敗しました')),
              );
            }
          },
        ),

        // YouTube 動画ダイアログ
        onTap: () {
          if (videoId != null) {
            _showYoutubeDialog(videoId);
          } else {
            print("無効なYouTube URL: $url , $videoId");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("無効なYouTube動画URLです")),
            );
          }
        },
      ),
    );
  }

  void handleNavigate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumInfoPage(curriculum: widget.curriculum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.curriculum['name'] ?? 'カリキュラム詳細'),
        actions: [
          TextButton(
            onPressed: handleNavigate,
            child: Text(
              'このカリキュラムについて',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => HomePage()),
                (route) => false, // すべての既存ルートを削除
              );
            },
            child: const Text(
              'ホームに戻る',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return buildMovieCard(index, movies[index]);
          }
        ),
      ),
    );
  }
}
