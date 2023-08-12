import 'package:flutter/material.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:sc/settings_service.dart';
import 'secondmodal.dart';
import 'package:intl/intl.dart';
class AddEventDialog extends StatefulWidget {
  final VoidCallback onDialogClosed;

  const AddEventDialog({Key? key, required this.onDialogClosed}) : super(key: key);


  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  DateTime? startDateTime;
  DateTime? endDateTime;
  String? notes;
  Duration defaultDuration = Duration(hours: 2); // adjustable default duration
  SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadIntervalValue();
  }

  Future<void> _loadIntervalValue() async {
    String intervalValue = await _settingsService.getIntervalValue();
    defaultDuration = Duration(hours: int.parse(intervalValue.split(' ')[0]));
    setState(() {});
  }

  Future<void> _selectStartDateTime(BuildContext context) async {
    final DateTime? picked = await showOmniDateTimePicker(
      context: context,
      initialDate: startDateTime ?? DateTime.now(),
      firstDate: DateTime(1600).subtract(Duration(days: 3652)),
      lastDate: DateTime.now().add(Duration(days: 3652)),
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
      initialDate: endDateTime ?? (startDateTime ?? DateTime.now()).add(defaultDuration),
      firstDate: DateTime(1600).subtract(Duration(days: 3652)),
      lastDate: DateTime.now().add(Duration(days: 3652)),
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

      title: const Text('Add new Event'),
      content: SingleChildScrollView(

        child: Column(
          children: [
            TextButton(
              onPressed: () => _selectStartDateTime(context),
              child: Row(
                children: [
                  Text('From: '),
                  Text(
                      startDateTime!= null ? DateFormat('h:mm a').format(startDateTime!) : 'Not set',

                      style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _selectEndDateTime(context),
              child: Row(
                children: [
                  Text('To: '),
                  Text(
                    endDateTime!= null ? DateFormat('h:mm a').format(endDateTime!) : 'Not set',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  notes = value;
                });
              },
              decoration: InputDecoration(hintText: 'Enter notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if(startDateTime != null && endDateTime != null){
              Navigator.pop(context);
              showDialog(
                context: context,

                builder: (BuildContext context) {
                  return ConfirmEventDialog(
                    startDateTime: startDateTime!,
                    endDateTime: endDateTime!,
                    notes: notes ?? '',
                    onDialogClosed: widget.onDialogClosed,
                  );
                },
              );
            } else {
              print("Please make sure all fields are filled.");
            }
          },
          child: Text('Next'),
        ),
      ],
    );
  }
}




