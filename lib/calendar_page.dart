import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'event.dart';
import 'event_service.dart'; // Убедитесь, что импортирован правильный файл
import 'settings_service.dart';
import 'package:sc/add_event_dialog.dart';
import 'package:sc/edit_event_dialog.dart';


class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});




  @override
  _CalendarPageState createState() => _CalendarPageState();
}
class TimeFrame {
  final TimeOfDay startHour;
  final TimeOfDay endHour;

  TimeFrame(this.startHour, this.endHour);
}

class _CalendarPageState extends State<CalendarPage> {
  late List<Event> _events = [];
  late DateTime _currentStartDate;
  Future<TimeFrame>? _timeFrame;
  // New interval variable
  void updateCalendarData() async {
    int numberOfDays = await SettingsService().getNumberOfDays();
    List<Event> events = await fetchEventsForWeek(_currentStartDate, numberOfDays);

    setState(() {
      _events = events;

    });
  }


  final SettingsService _settingsService = SettingsService();
  final List<String> _numberOfDaysList = <String>[
    '1 day',
    '2 days',
    '3 days',
    '4 days',
    '5 days',
    '6 days',
    '7 days'
  ].toList();

  String _numberOfDaysString = 'default';
  int _numberOfDays = -1;
  // New interval variables
  final List<String> _intervalValueList = <String>[
    '1 hour',
    '2 hours',
    '3 hours',
    '4 hours',
    '5 hours'
  ].toList();
  String _intervalValueString = '3 hours';
  Duration _intervalValue = const Duration(hours: 3);
// Method to handle interval value change
  void customIntervalValue(String value) {
    _intervalValueString = value;
    if (value == '1 hour') {
      _intervalValue = const Duration(hours: 1);
    } else if (value == '2 hours') {
      _intervalValue = const Duration(hours: 2);
    } else if (value == '3 hours') {
      _intervalValue = const Duration(hours: 3);
    } else if (value == '4 hours') {
      _intervalValue = const Duration(hours: 4);
    } else if (value == '5 hours') {
      _intervalValue = const Duration(hours: 5);
    }
    _settingsService.saveIntervalValue(_intervalValue.inHours.toString());
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _settingsService.getNumberOfDays().then((numberOfDays) {
      setState(() {
        _numberOfDays = numberOfDays;
        _numberOfDaysString = '$_numberOfDays day${_numberOfDays > 1 ? 's' : ''}';
      });
    });
    _settingsService.getIntervalValue().then((intervalValueString) {
      int intervalInHours = int.parse(intervalValueString);
      _intervalValue = Duration(hours: intervalInHours);
      _intervalValueString = "$intervalInHours hour${intervalInHours > 1 ? 's' : ''}";
      setState(() {});
    });
    _currentStartDate = DateTime.now();
    _timeFrame = _getTimeFrame();
  }

  /// Allows to switching the days count customization in calendar.
  void customNumberOfDaysInView(String value) {
    _numberOfDaysString = value;
    if (value == 'default') {
      _numberOfDays = -1;
    } else if (value == '1 day') {
      _numberOfDays = 1;
    } else if (value == '2 days') {
      _numberOfDays = 2;
    } else if (value == '3 days') {
      _numberOfDays = 3;
    } else if (value == '4 days') {
      _numberOfDays = 4;
    } else if (value == '5 days') {
      _numberOfDays = 5;
    } else if (value == '6 days') {
      _numberOfDays = 6;
    } else if (value == '7 days') {
      _numberOfDays = 7;
    }
    _settingsService.saveNumberOfDays(_numberOfDays);
    setState(() {});
  }
  @override
  Widget buildSettings(BuildContext context) {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          return ListView(
            shrinkWrap: true,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                      child: Text('Number of days',
                          softWrap: false,
                          style:
                          TextStyle(fontSize: 16.0))),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 30),
                      alignment: Alignment.bottomLeft,
                      child: DropdownButton<String>(
                          focusColor: Colors.transparent,
                          underline:
                          Container(color: const Color(0xFFBDBDBD), height: 1),
                          value: _numberOfDaysString,
                          items: _numberOfDaysList.map((String value) {
                            return DropdownMenuItem<String>(
                                value: (value != null) ? value : 'default',
                                child: Text(value,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.black)));
                          }).toList(),
                          onChanged: (dynamic value) {
                            customNumberOfDaysInView(value);
                            stateSetter(() {});
                            Navigator.pop(context); // Закрывает модальное окно после выбора количества дней
                          }),
                    ),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Interval',
                      softWrap: false,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 30),
                      alignment: Alignment.bottomLeft,
                      child: DropdownButton<String>(
                        focusColor: Colors.transparent,
                        underline: Container(
                          color: const Color(0xFFBDBDBD),
                          height: 1,
                        ),
                        // Assuming you have a variable for selected interval value
                        value: _intervalValueString,
                        // And assuming you have a list of possible interval values
                        items: _intervalValueList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: (value != null) ? value : 'default',
                            child: Text(
                              value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black),
                            ),
                          );
                        }).toList(),
                        onChanged: (dynamic value) {
                          customIntervalValue(value);
                          stateSetter(() {});
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
    );
  }
  void _updateEvents() async {
    List<Event> events = await fetchEventsForWeek(_currentStartDate, _numberOfDays);

    setState(() {
      _events = events;
    });
  }






  Future<TimeFrame> _getTimeFrame() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? timeframe = prefs.getString("timeframe");

    if (timeframe == null) {
      throw Exception('Timeframe not found');
    }

    List<String> times = timeframe.split('-');
    TimeOfDay startHour = _parseTime(times[0].trim());
    TimeOfDay endHour = _parseTime(times[1].trim());

    return TimeFrame(startHour, endHour);
  }

  TimeOfDay _parseTime(String time) {
    final format = DateFormat("h:mm a");
    DateTime dt = format.parse(time);
    return TimeOfDay.fromDateTime(dt);
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TimeFrame>(
      future: _timeFrame,
      builder: (BuildContext context, AsyncSnapshot<TimeFrame> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text("Calendar"),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: Container(
                            margin: const EdgeInsets.all(10.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueAccent)
                            ),
                            width: MediaQuery.of(context).size.width * 0.4, // 80% от ширины экрана
                            child: buildSettings(context),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddEventDialog(onDialogClosed: updateCalendarData);
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
            body: SfCalendar(
              view: CalendarView.week,
              timeSlotViewSettings: TimeSlotViewSettings(
                startHour: snapshot.data!.startHour.hour.toDouble(),
                endHour: snapshot.data!.endHour.hour.toDouble(),
                numberOfDaysInView: _numberOfDays,
                timeIntervalHeight: 60,
                timeIntervalWidth: 100,
              ),
              dataSource: EventDataSource(_events as List<Event>),
              allowDragAndDrop:false,
              onViewChanged: (ViewChangedDetails details) async {
                DateTime visibleStartDate = details.visibleDates.first;
                int numberOfDays = await SettingsService().getNumberOfDays();

                if (_currentStartDate != visibleStartDate || _numberOfDays != numberOfDays) {
                  _currentStartDate = visibleStartDate;
                  _numberOfDays = numberOfDays;

                  // Здесь мы загружаем события вместо метода _loadEventsForWeekStarting
                  List<Event> events = await fetchEventsForWeek(visibleStartDate, numberOfDays);

                  setState(() {
                    _events = events;
                  });
                }
              },
              onTap: (CalendarTapDetails details) {
                if (details.appointments != null) {
                  final Event event = details.appointments!.first as Event;

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        titlePadding: EdgeInsets.all(0),
                        title: Container(
                          color: Colors.blue,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  event.num,
                                  style: TextStyle(color: Colors.white),
                                ),
                                Row(
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.white),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return EditEventDialog(
                                              event: event,
                                              onDialogClosed: _updateEvents,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    TextButton(
                                      child: Text('OK', style: TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (event.status == 'time_off') ...[
                              Text(
                                '📅 ${DateFormat('EEE, MMM d, y').format(DateTime.parse(event.start))}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '⏰ ${DateFormat('hh:mm a').format(DateTime.parse(event.start))} - ${DateFormat('hh:mm a').format(DateTime.parse(event.end))}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Divider(color: Colors.black), // Это добавляет горизонтальную линию

                              if(event.description.isNotEmpty)
                                Text(event.description),

                              const Text("Assigned to:", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold )),
                              Text(event.assignedTo.join(', ')),



                              const SizedBox(height: 20.0),
                              Text(event.serviceDescription),
                              ] else ...[
                              Text(
                                '📅 ${DateFormat('EEE, MMM d, y').format(DateTime.parse(event.start))}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '⏰ ${DateFormat('hh:mm a').format(DateTime.parse(event.start))} - ${DateFormat('hh:mm a').format(DateTime.parse(event.end))}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Divider(color: Colors.black), // Это добавляет горизонтальную линию
                              const Text("Job : ", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold )),
                              ...[
                                if(event.applianceName.isNotEmpty && event.applianceBrand.isNotEmpty)
                                  Text("${event.applianceName} / ${event.applianceBrand}")
                                else if(event.applianceName.isNotEmpty)
                                  Text(event.applianceName)
                                else if(event.applianceBrand.isNotEmpty)
                                    Text(event.applianceBrand),
                              ],
                              Text("By ${event.company}", style: const TextStyle(fontStyle: FontStyle.italic)),
                              if(event.description.isNotEmpty)
                                Text(event.description),
                              const Text("Contact: ",style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold )),
                              Text( " ${event.contactName}",style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ElevatedButton(
                                child: Text(event.contactAddress),
                                onPressed: () {
                                  MapsLauncher.launchQuery(event.contactAddress);
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
                                    child: Text("${event.phone1Desc}: ${event.phone1}"),
                                  ),
                                  TextButton(
                                    child: const Text("Call"),
                                    onPressed: () async {
                                      final call = Uri.parse('tel:${event.phone1}');
                                      if (await canLaunchUrl(call)) {
                                        launchUrl(call);
                                      } else {
                                        throw 'Could not launch $call';
                                      }
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("SMS"),
                                    onPressed: () async {
                                      final sms = Uri.parse('sms:${event.phone1}');
                                      if (await canLaunchUrl(sms)) {
                                        launchUrl(sms);
                                      } else {
                                        throw 'Could not launch $sms';
                                      }
                                    },
                                  ),
                                ],
                              ),
                              if(event.phone2Desc.isNotEmpty && event.phone2.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text("${event.phone2Desc}: ${event.phone2}"),
                                    ),
                                    TextButton(
                                      child: const Text("Call"),
                                      onPressed: () async {
                                        final call = Uri.parse('tel:${event.phone2}');
                                        if (await canLaunchUrl(call)) {
                                          launchUrl(call);
                                        } else {
                                          throw 'Could not launch $call';
                                        }
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("SMS"),
                                      onPressed: () async {
                                        final sms = Uri.parse('sms:${event.phone2}');
                                        if (await canLaunchUrl(sms)) {
                                          launchUrl(sms);
                                        } else {
                                          throw 'Could not launch $sms';
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              if(event.phone3Desc.isNotEmpty && event.phone3.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text("${event.phone3Desc}: ${event.phone3}"),
                                    ),
                                    TextButton(
                                      child: const Text("Call"),
                                      onPressed: () async {
                                        final call = Uri.parse('tel:${event.phone3}');
                                        if (await canLaunchUrl(call)) {
                                          launchUrl(call);
                                        } else {
                                          throw 'Could not launch $call';
                                        }
                                      },
                                    ),
                                    TextButton(
                                      child: const Text("SMS"),
                                      onPressed: () async {
                                        final sms = Uri.parse('sms:${event.phone3}');
                                        if (await canLaunchUrl(sms)) {
                                          launchUrl(sms);
                                        } else {
                                          throw 'Could not launch $sms';
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              const Text("Assigned to:", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold )),
                              Text(event.assignedTo.join(', ')),



                              const SizedBox(height: 20.0),
                              Text(event.serviceDescription),


                          ],
                          ],
                        ),
                      );
                    },
                  );

                }
              },
            ),
          );
        }
      },

    );
  }



}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Event> source) {
    appointments = source;
  }




  @override
  DateTime getStartTime(int index) {
    return DateTime.parse(appointments![index].start);
  }

  @override
  DateTime getEndTime(int index) {
    return DateTime.parse(appointments![index].end);
  }

  @override
  String getSubject(int index) {
    if (appointments![index].status == 'time_off'){
      Event event = appointments![index] as Event;
      return '  ${event.description}\n Assigned to: ${event.assignedTo.join(', ')}\n';
    } else {
      Event event = appointments![index] as Event;
      return ' ${event.num} \n ${event.contactName} \n ${event
          .description}\n ${event.contactAddress}\n';
    }

  }

  @override
  Color getColor(int index) {
    if (appointments![index].status == 'time_off') {

      return Colors.black26; // или же просто вернуть красный цвет
    } else {
      String colorString = appointments![index].color; // Например, #3F51B5
      String colorHex = colorString.replaceAll("#", ""); // Удаляем '#'
      Color color = Color(int.parse(colorHex, radix: 16)).withOpacity(1);
      return color;
    }
  }

}

