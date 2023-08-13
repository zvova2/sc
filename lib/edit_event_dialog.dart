import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:sc/settings_service.dart';
import 'package:intl/intl.dart';
import 'package:sc/event.dart';
import 'package:http/http.dart' as http;
import 'package:sc/constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> editEvent({
  required int eventId,
  required String description,
  required String startDate,
  required String endDate,
  required List<String> userIds
}) async {
  var url = Uri.parse('$baseUrl/eventHandler.php');

  var headers = {
    'Content-Type': 'application/json'
  };

  var body = jsonEncode({
    'request_type': 'editEvent',
    'event_id': eventId,
    'description': description,
    'start_date': startDate,
    'end_date': endDate,
    'user_ids': userIds,
  });

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (data['status'] == 1) {
      print('Event Updated successfully!');
      return true;
    } else {
      print('Error: ' + data['error']);
      return false;
    }
  } else {
    throw Exception('Failed to load data');
  }
}




class EditEventDialog extends StatefulWidget {
  final Event event;
  final VoidCallback onDialogClosed;

  const EditEventDialog({Key? key, required this.event, required this.onDialogClosed,}) : super(key: key);

  @override
  _EditEventDialogState createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  late DateTime startDateTime;
  late DateTime endDateTime;
  late TextEditingController notesController;
  String? notes;
  Duration defaultDuration = const Duration(hours: 2); // adjustable default duration
  final SettingsService _settingsService = SettingsService();
  @override
  void initState() {
    super.initState();
    startDateTime = DateTime.parse(widget.event.start);

    endDateTime = DateTime.parse (widget.event.end);
    notesController = TextEditingController(text: widget.event.description); // Инициализируйте его здесь с описанием события.
    notes = widget.event.description;

    _loadIntervalValue().then((_) {

      endDateTime = startDateTime.add(defaultDuration);
      setState(() {});
    });

  }
  Future<void> _loadIntervalValue() async {
    String intervalValue = await _settingsService.getIntervalValue();
    defaultDuration = Duration(hours: int.parse(intervalValue.split(' ')[0]));
    setState(() {});
  }
  Future<void> _selectStartDateTime(BuildContext context) async {
    final DateTime? picked = await showOmniDateTimePicker(
      context: context,
      initialDate: startDateTime,
      firstDate: DateTime(1600).subtract(const Duration(days: 3652)),
      lastDate: DateTime.now().add(const Duration(days: 3652)),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 30,
    );

    if (picked != null) {
      setState(() {
        startDateTime = picked;
        endDateTime = picked.add(defaultDuration);
      });
    }
  }

  Future<void> _selectEndDateTime(BuildContext context) async {
    final DateTime? picked = await showOmniDateTimePicker(
      context: context,
      initialDate: endDateTime,
      firstDate: DateTime(1600).subtract(const Duration(days: 3652)),
      lastDate: DateTime.now().add(const Duration(days: 3652)),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 30,
    );

    if (picked != null) {
      setState(() {
        endDateTime = picked;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFCCD6E0),


      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32.0))),
      contentPadding: const EdgeInsets.only(top: 10.0),

      title: const Text('Edit Event'),
      content: SingleChildScrollView(

        child: Column(
          children: [
            TextButton(
              onPressed: () => _selectStartDateTime(context),
              child: Row(
                children: [
                  const Text('From: '),
                  Text(
                    DateFormat('h:mm a').format(startDateTime),

                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _selectEndDateTime(context),
              child: Row(
                children: [
                  const Text('To: '),
                  Text(
                    DateFormat('h:mm a').format(endDateTime),
                    style: const TextStyle(color: Colors.black),
                  )

                ],
              ),
            ),
            TextField(
              controller: notesController, // Используйте контроллер здесь.
              onChanged: (value) {
                setState(() {
                  notes = value;
                });
              },
              decoration: const InputDecoration(hintText: 'Enter notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              String? userId = prefs.getString("user_id");

              int eventIdInt = int.tryParse(widget.event.id) ?? 0;  // Преобразование из строки в число, если невозможно преобразовать, будет использоваться значение по умолчанию 0.

              bool success = await editEvent(
                eventId: eventIdInt,
                description: notes ?? "",
                startDate: startDateTime.toIso8601String(),
                endDate: endDateTime.toIso8601String(),
                userIds: userId != null ? [userId] : [],
              );
              if(success){
                widget.onDialogClosed();
                Navigator.pop(context);
              }

          },
          child: const Text('Update'),
        )




      ],
    );
  }
}
