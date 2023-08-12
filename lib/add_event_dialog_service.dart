import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final int id;
  final String role;
  final String username;

  User({required this.id, required this.role, required this.username});

  // метод для создания экземпляра User из Map<String, dynamic>
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      role: json['role'],
      username: json['username'],
    );
  }
}
class AddEventDialogService {
  final String apiUrl = baseUrl;

  Future<List<String>> getCompanies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");
    String? jwt = prefs.getString("jwt");
    final response = await http.get(
      Uri.parse('$baseUrl/get_user_companies.php'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode == 200) {
      // Если сервер возвращает ответ ОК, то парсим тело ответа
      List<dynamic> companyList = json.decode(response.body);
      // Преобразуем список dynamic в список String
      List<String> companies = companyList.cast<String>();
      return companies;
    } else {
      // Если ответ не ОК, кидаем исключение
      throw Exception('Failed to load companies');
    }
  }



  Future<List<User>> getUsers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwt = prefs.getString("jwt");

    final response = await http.post(
      Uri.parse('$baseUrl/fetch_users.php'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: jsonEncode({
        'request_type': 'fetchAllUsers',
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<User> users = body.map((dynamic item) => User.fromJson(item)).toList();
      return users;
    } else {
      throw Exception("Failed to load users");
    }
  }



  Future<bool> submitEvent(Map<String, dynamic> eventData) async {
    final response = await http.post(
      Uri.parse(apiUrl + "/submit_event"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to submit event');
    }
  }
}
