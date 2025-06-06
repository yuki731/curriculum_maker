import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'main.dart' as app;

void main() {
  setUrlStrategy(PathUrlStrategy()); // URLの#を消すため（任意）
  app.main();
}
