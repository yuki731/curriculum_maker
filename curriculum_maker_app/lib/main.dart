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
        textTheme: GoogleFonts.openSansTextTheme(), // Open Sans 使用
        // textTheme: GoogleFonts.robotoTextTheme(), // Roboto 使用したいときはこちら
        // fontFamily: 'NotoSansJP',  // ここで日本語フォント指定
      ),
      routes: {
        '/home': (context) => HomePage(),
        '/signup': (context) => SignupPage(),
        '/': (context) => LoginPage(),
      },
    );
  }
}
