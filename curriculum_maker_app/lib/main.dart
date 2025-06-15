import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/widgets.dart';
import 'pages/home_page.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';
import 'pages/curriculum_make_page.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Curriculum Maker',
      navigatorObservers: [routeObserver],
      initialRoute: '/',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,          // ★白を指定
          brightness: Brightness.light,     // 明るいテーマ
        ),
        scaffoldBackgroundColor: Colors.white,  // 画面全体の背景も白に
        useMaterial3: true,
        textTheme: GoogleFonts.openSansTextTheme(),
      ),
      routes: {
        '/home': (context) => HomePage(),
        '/signup': (context) => SignupPage(),
        '/': (context) => LoginPage(),
      },
    );
  }
}
