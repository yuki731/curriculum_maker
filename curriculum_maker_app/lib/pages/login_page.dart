// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String username = '';
  String password = '';
  String message = '';
  String access = '';
  String refresh = '';
  final _formKey = GlobalKey<FormState>();

void handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();  
        final result = await AuthService.login(username, password);
        if (result['success']) {
            String newAccess = result['data']['access'];
            String newRefresh = result['data']['refresh'];

            await TokenStorage.saveTokens(newAccess, newRefresh);

            setState(() {
            message = 'Login success';
            access = newAccess;
            refresh = newRefresh;
            });

            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            );
        } else {
            setState(() {
            message = 'Login failed: ${result['data']}';
            });
        }
    }
}

void handleNavigate() async {
    Navigator.push (
        context,
        MaterialPageRoute(builder: (context) => SignupPage()),
    );
}

  void handleRefresh() async {
    final result = await AuthService.refresh(refresh);
    if (result['success']) {
      setState(() {
        access = result['data']['access'];
        message = 'Token refreshed';
      });
    } else {
      setState(() {
        message = 'Refresh failed: ${result['data']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log In')),
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
                    handleLogin();  // Enter押したら送信
                    },
                    ),
                    ElevatedButton(
                    onPressed: handleLogin,
                    child: Text(
                        'Log In',
                        style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    ),
                    TextButton(
                    onPressed: handleNavigate,
                    child: Text(
                        'アカウントをお持ちでない方はこちら',
                        style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w900,
                        ),
                    ),
                    ),
                    SizedBox(height: 10),
                    Text(
                    message,
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w900,
                    ),
                    ),

            ],
            ),
        ),
      ),
    );
  }
}
