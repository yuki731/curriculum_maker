// lib/pages/signup_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String username = '';
  String password = '';
  String message = '';
  final _formKey = GlobalKey<FormState>();

void handleSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save(); 
        final result = await AuthService.signup(username, password);
        if (result['success']) {
            // 成功メッセージを表示（任意）
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup success!')));
            handleNavigate();
        } else {
            setState(() {
            message = 'Signup failed: ${result['data']}';
            });
        }
    }
}

void handleNavigate() async {
    // LoginPageに遷移
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: Column(
            children: [
                TextFormField(
                    decoration: InputDecoration(labelText: 'Username'),
                    onSaved: (val) => username = val ?? '',
                    validator: (val) => val == null || val.isEmpty ? 'Please enter username' : null,
                    textInputAction: TextInputAction.next,
                ),
                TextFormField(
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onSaved: (val) => password = val ?? '',
                    validator: (val) => val == null || val.isEmpty ? 'Please enter password' : null,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                    handleSignup();  // Enter押したら送信
                    },
                ),
                ElevatedButton(onPressed: handleSignup, child: Text('Sign Up')),
                TextButton(
                    onPressed: handleNavigate,
                    child: Text(
                        'アカウントをお持ちの方はこちら',
                        style: TextStyle(decoration: TextDecoration.underline),
                    ),
                ),
                Text(message, style: TextStyle(color: Colors.red)),
            ],
            ),
        ),
      ),
    );
  }
}
