import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
        title: Text(title),
        trailing: Checkbox(
          value: isCheckedList[index],
          onChanged: (bool? value) async {
            final newStatus = value ?? false;

            setState(() {
              isCheckedList[index] = newStatus;
            });

            try {
              await AuthService.updateMovieStatus(
                widget.curriculum['id'],
                movies[index]['id'],
                newStatus,
              );
            } catch (e) {
              print('ステータス更新失敗: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ステータス更新に失敗しました')),
              );
            }
          },
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.curriculum['name'] ?? 'カリキュラム詳細')),
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
