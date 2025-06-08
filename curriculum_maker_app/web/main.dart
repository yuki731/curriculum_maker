import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'main.dart' as app;

void main() {
  setUrlStrategy(PathUrlStrategy());

  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(
    'youtube-player-html',
    (int viewId) {
      final iframe = html.IFrameElement()
        ..width = '640'
        ..height = '360'
        ..src = 'about:blank'  // 本体はyoutube_player_iframe側で差し替えるので空でOK
        ..style.border = 'none';
      return iframe;
    },
  );

  app.main();
}
