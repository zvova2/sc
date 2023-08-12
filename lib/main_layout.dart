import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_check.dart';
import 'constants.dart';
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jwt = prefs.getString('jwt') ?? '';

    if (jwt.isNotEmpty) {
      // декодируем токен
      final parts = jwt.split('.');
      if (parts.length != 3) {
        if (kDebugMode) {
          print("jwt format is incorrect");
        }
        return;
      }

      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      // Логирование payload для проверки
      if (kDebugMode) {
        print("Decoded payload: $payload");
      }

      // передаем данные из токена в функцию userCheck
      var userInfo = await userCheck({
        'user_id': payload['data']['id'], // Используем 'data' ключ, так как ID находится внутри 'data'
        'username': payload['data']['username'],
        'role': payload['data']['role']
      }, jwt);

      if (kDebugMode) {
        print("User info received from userCheck: $userInfo");
      } // Логирование информации о пользователе

      // Сохранение информации о пользователе в SharedPreferences
      //prefs.setString("user_id", payload['data']['id'].toString());

      prefs.setString("logo_url", userInfo["companyLogo"] ?? '');
      prefs.setString("user_initials", userInfo["user_initials"] ?? '');
    }
    if (mounted) {
    setState(() {});
 }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule App"),
        leading: FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              String? logoUrl = snapshot.data?.getString("logo_url");

              return (logoUrl != null) ? Image.network('$baseUrl/logo/$logoUrl') : Container();
            }
            return Container();
          },
        ),
        actions: [
          FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                String? userInitials = snapshot.data?.getString("user_initials");
                return Row(
                  children: [
                    if (userInitials != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(userInitials, style: const TextStyle(fontSize: 24)),
                      ),
                    ],
                    PopupMenuButton(
                      onSelected: (value) async {
                        if (value == 'logout') {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('jwt');
              await prefs.remove('user_id');
              await prefs.remove('user_initials');
              await prefs.remove('logo_url');

              // Затем, вы можете перенаправить пользователя на страницу входа
              Navigator.of(context).pushReplacementNamed('/login');
              }
              },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.exit_to_app),
                              Text('Logout'),
                            ],
                          ),
                        ),
                        // Добавьте дополнительные элементы меню здесь...
                      ],
                    ),
                  ],
                );
              }
              return Container();
            },
          ),
        ],

      ),
      body: widget.child,
    );
  }

}

