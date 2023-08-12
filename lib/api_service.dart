import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
class ApiService {
  final String apiUrl = "$baseUrl/api.php";

  Future<void> getContacts() async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?action=getContacts"));

      if (response.statusCode == 200) {

        print('Response data: ${json.decode(response.body)}');
      } else {

        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {

      print("Error fetching data: $e");
    }
  }

}
