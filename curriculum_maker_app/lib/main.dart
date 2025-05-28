import 'package:flutter/material.dart';
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
      title: 'JWT Auth Flutter',
      initialRoute: '/',
      routes: {
        '/home': (context) => HomePage(),
        '/signup': (context) => SignupPage(),
        '/': (context) => LoginPage(),
      },
    );
  }
}
