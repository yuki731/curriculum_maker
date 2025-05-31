import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/home_page.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Curriculum Maker',
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
