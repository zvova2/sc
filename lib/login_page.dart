import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // отправляем данные на сервер
      final response = await http.post(
        Uri.parse('$baseUrl/loginmob.php'),
        body: jsonEncode({
          'username': _username,
          'password': _password,
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        var jsonResponse = json.decode(response.body);

        // Get the JWT from the response
        String jwt = jsonResponse['jwt'];

        final parts = jwt.split('.');
        if (parts.length != 3) {
          throw Exception('invalid token');
        }

        final payload = json.decode(utf8.decode(base64.decode(base64.normalize(parts[1]))));

        if (payload.containsKey('data')) {
          var data = payload['data'];
          if (data.containsKey('id') && data.containsKey('role')) {
            String userId = data['id'].toString();
            String role = data['role'].toString();

            // Save JWT and user_id in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            prefs.setString('jwt', jwt);
            prefs.setString('user_id', userId);
            prefs.setString('role', role);
          } else {
            throw Exception('ID or role not found in the token data');
          }
        } else {
          throw Exception('Data not found in the token');
        }





        // Navigate to the home page
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Show an error message
        print('Failed to log in.');
      }
    }
  }




@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                onSaved: (value) {
                  _username = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _submitForm();
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

