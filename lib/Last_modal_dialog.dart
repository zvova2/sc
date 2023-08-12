import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
List<dynamic> _appliances = [];
List<dynamic> _brands = [];




class LastModalDialog extends StatefulWidget {
  final VoidCallback onDialogClosed;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String notes;
  final int selectedContactId;

  const LastModalDialog({
    Key? key,
    required this.onDialogClosed,
    required this.startDateTime,
    required this.endDateTime,
    required this.notes,
    required this.selectedContactId,

  }) : super(key: key);

  @override
  _LastModalDialogState createState() => _LastModalDialogState();
}

class _LastModalDialogState extends State<LastModalDialog> {
  int? _selectedApplianceId;
  int? _selectedBrandId;

  final TextEditingController _descriptionController = TextEditingController();

  void fetchData() async {
    // Загрузка списка appliances
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? companyId = prefs.getString("companyId");
    final responseAppliances = await http.get(Uri.parse('$baseUrl/api.php?action=getAppliances&company_id=$companyId'));
    if (responseAppliances.statusCode == 200) {
      setState(() {
        _appliances = json.decode(responseAppliances.body);
      });
    }

    // Загрузка списка brands
    final responseBrands = await http.get(Uri.parse('$baseUrl/api.php?action=getBrands&company_id=$companyId'));
    if (responseBrands.statusCode == 200) {
      setState(() {
        _brands = json.decode(responseBrands.body);
      });
    }
  }
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: const Color(0xFFCCD6E0),


        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        contentPadding: const EdgeInsets.only(top: 10.0),
      title: const Text('Appliance Information'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField(
              items: _appliances.map((item) {
                return DropdownMenuItem(
                  child: Text(item['name']),
                  value: item['id'],
                );
              }).toList(),
              decoration: const InputDecoration(hintText: 'Select appliance'),
              onChanged: (value) {
                setState(() {
                  _selectedApplianceId = int.parse(value.toString());
                });
              },

            ),
            DropdownButtonFormField(
              items: _brands.map((item) {
                return DropdownMenuItem(
                  child: Text(item['name']),
                  value: item['id'],
                );
              }).toList(),
              decoration: const InputDecoration(hintText: 'Select brand'),
              onChanged: (value) {
                setState(() {
                  _selectedBrandId = int.parse(value.toString());
                });
              },
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(hintText: 'Enter description'),
            ),

          ],
        ),
      ),
        actions: [
          TextButton(
            onPressed: () async {
              // собираем все данные
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              String? userId = prefs.getString("user_id");
              String? username = prefs.getString("username");
              String? companyId = prefs.getString("companyId");
              Map<String, dynamic> jobData = {
                'company_id': companyId,
                'contact_id': widget.selectedContactId.toString(),
                'created_at': DateTime.now().toIso8601String(), // текущее время
                'created_by': username,
                'service': _selectedApplianceId.toString(),
                'service_description': _descriptionController.text,
                'status': 'active', // можно изменить на реальное значение
                'sub_service': _selectedBrandId.toString(),
              };

              // выполняем HTTP POST запрос для addJob
              var response = await http.post(
                Uri.parse('$baseUrl/api.php?action=addjob'),
                headers: {
                  'Content-Type': 'application/json',
                },
                body: json.encode(jobData),
              );

              if (response.statusCode == 200) {
                final jsonResponse = json.decode(response.body);
                if (jsonResponse['success']) {
                  print('Job ID: ${jsonResponse['id']}');

                  // Если первый запрос успешен, делаем второй запрос для addEvent
                  Map<String, dynamic> eventData = {
                    'company_id': companyId, // можно изменить на реальное значение
                    'created_at': DateTime.now().toIso8601String(),
                    'created_by': username,
                    'description': widget.notes,
                    'end_date': widget.endDateTime.toIso8601String(),
                    'job_id': jsonResponse['id'], // job_id, полученный из предыдущего запроса
                    'start_date': widget.startDateTime.toIso8601String(), // преобразовываем DateTime в строку в формате ISO8601
                    'status': 'active', // можно изменить на реальное значение
                    'user_ids': [userId],

                  };

                  // выполняем HTTP POST запрос для addEvent
                  response = await http.post(
                    Uri.parse('$baseUrl/api.php?action=addEvent'),
                    headers: {
                      'Content-Type': 'application/json',
                    },
                    body: json.encode(eventData),
                  );

                  if (response.statusCode == 200) {
                    final jsonResponse = json.decode(response.body);
                    if (jsonResponse['success']) {
                      print('Event ID: ${jsonResponse['id']}');
                      // Если второй запрос успешен, делаем третий запрос для addevent_user
                      Map<String, dynamic> eventUserData = {
                        'event_id': jsonResponse['id'],
                        'user_ids': [userId],
                      };

                      // выполняем HTTP POST запрос для addevent_user
                      response = await http.post(
                        Uri.parse('$baseUrl/api.php?action=addevent_user'),
                        headers: {
                          'Content-Type': 'application/json',
                        },
                        body: json.encode(eventUserData),
                      );

                      if (response.statusCode == 200) {
                        final jsonResponse = json.decode(response.body);
                        if (jsonResponse.isNotEmpty && !jsonResponse[0]['success']) {
                          print('Error: ${jsonResponse[0]['error']}');
                        }
                      } else {
                        print('Error: ${response.statusCode}');
                      }

                    } else {
                      print('Error: ${jsonResponse['error']}');
                    }
                  } else {
                    print('Error: ${response.statusCode}');
                  }

                } else {
                  print('Error: ${jsonResponse['error']}');
                }
              } else {
                print('Error: ${response.statusCode}');
              }
              widget.onDialogClosed();  // Важно: убедитесь, что этот callback определен и не равен null
              // закрываем последний диалог
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),

        ]

    );
  }
}
