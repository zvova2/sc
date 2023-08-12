import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
Future<Map<String, dynamic>> userCheck(Map<String, dynamic> userData, String jwt) async {
  const url = '$baseUrl/user_check.php';

  final response = await http.post(
    Uri.parse(url),
    body: jsonEncode({
      'request_type': 'getCurrentUser',
      'user_data': userData,
      // Опционально: если вам все еще нужны данные пользователя в запросе
    }),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $jwt"
    },
  );

  if (response.statusCode == 200) {
    // Декодирование ответа
    var userInfo = jsonDecode(response.body);

    // Сохранение данных в SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //prefs.setString("user_id", userInfo["id"].toString());
    prefs.setString("loginName", userInfo["loginName"] ?? '');
    prefs.setString("companyId", userInfo["companyId"] ?? '');
    prefs.setString("username", userInfo["username"] ?? '');
    //prefs.setString("role", userInfo["role"] ?? '');
    prefs.setString("timeframe", userInfo["timeframe"] ?? '');
    //prefs.setString("companyLogo", userInfo["companyLogo"] ?? '');
    //prefs.setString("user_initials", userInfo["user_initials"] ?? '');

    // Возвращаем информацию о пользователе
    return userInfo;
  } else {
    throw Exception('Failed to load user info');
  }
}
