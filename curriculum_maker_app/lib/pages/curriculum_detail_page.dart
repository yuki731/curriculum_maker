import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CurriculumDetailPage extends StatefulWidget {
  final Map<String, dynamic> curriculum;

  const CurriculumDetailPage({required this.curriculum, Key? key}) : super(key: key);

  @override
  _CurriculumDetailPageState createState() => _CurriculumDetailPageState();
}

class _CurriculumDetailPageState extends State<CurriculumDetailPage> {
  List<Map<String, dynamic>> movies = [];
  Map<String, YoutubePlayerController> controllers = {};

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  void _loadMovies() async {
    try {
      final result = await AuthService.fetchMoviesByCurriculumId(widget.curriculum['id']);
      setState(() {
        movies = List<Map<String, dynamic>>.from(result);
      });
      _initControllers();
    } catch (e) {
      print('カリキュラム取得失敗: $e');
    }
  }

  void _initControllers() {
    for (var movie in movies) {
      final videoId = YoutubePlayer.convertUrlToId(movie['url']);
      if (videoId != null && !controllers.containsKey(videoId)) {
        controllers[videoId] = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(autoPlay: false, mute: false),
        );
      }
    }
  }

  // YouTube動画を表示するダイアログを開くメソッド
  void _showYoutubeDialog(String videoId, YoutubePlayerController controller) {

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
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: controller,
                showVideoProgressIndicator: true,
                onReady: () {
                  print("Player is ready");
                },
              ),
              builder: (context, player) => player,
            ),
          ),
          actions: [
            TextButton(
              child: Text("閉じる"),
              onPressed: () {
                controller.pause();
                Navigator.of(context).pop();
                controller.dispose();
              },
            )
          ],
        );
      },
    );
  }

  Widget buildMovieCard(Map<String, dynamic> movie) {
    String title = movie['title'] ?? 'タイトルなし';
    String url = movie['url'] ?? '';

    final videoId = YoutubePlayer.convertUrlToId(url);
    final controller = videoId != null ? controllers[videoId] : null;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(title),
        onTap: () {
          if (videoId != null && controller != null) {
            _showYoutubeDialog(videoId, controller);
          } else {
            print("無効なYouTube URL: $url");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("無効なYouTube動画URLです")),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.curriculum['name'] ?? 'カリキュラム詳細')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: movies.map((movie) => buildMovieCard(movie)).toList(),
        ),
      ),
    );
  }
}
