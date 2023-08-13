import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sc/login_page.dart';
import 'calendar_page.dart';
import 'main_layout.dart';
import 'event.dart';
import 'event_service.dart';
import 'package:intl/intl.dart';
import 'package:sc/constants.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:sc/edit_event_dialog.dart';

Future<bool> completeEvent(int eventId) async {
  var url = Uri.parse('$baseUrl/eventHandler.php');

  var headers = {
    'Content-Type': 'application/json'
  };

  var body = jsonEncode({
    'request_type': 'completeEvent',
    'event_id': eventId
  });

  var response = await http.post(url, headers: headers, body: body);
  print('Response body от completeEvent: ${response.body}');

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (data['status'] == 1) {
      print('Event Completed successfully!');
      return true;
    } else {
      print('Error: ' + data['error']);
      return false;
    }
  } else {
    throw Exception('Failed to load data');
  }
}

Future<bool> restartEvent(int eventId) async {
  var url = Uri.parse('$baseUrl/eventHandler.php');

  var headers = {
    'Content-Type': 'application/json'
  };

  var body = jsonEncode({
    'request_type': 'restartEvent',
    'event_id': eventId
  });

  var response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (data['status'] == 1) {
      print('Event Restarted successfully!');
      return true;
    } else {
      print('Error: ' + data['error']);
      return false;
    }
  } else {
    throw Exception('Failed to load data');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(EventAdapter());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const InitialPage(),
      routes: {
        '/home': (context) => MainLayout(child: HomePage()),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  _InitialPageState createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  @override
  void initState() {
    super.initState();
    checkIfUserIsLoggedIn();
  }

  checkIfUserIsLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwt = prefs.getString('jwt');

    if (jwt != null && jwt.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Event>> futureEvents;
  Future<bool> completeEventAndUpdate(int eventId) async {
    bool success = await completeEvent(eventId);
    if (success) {
      setState(() {
        futureEvents = fetchEvents(); // Обновляем список событий после завершения
      });
    }
    return success; // Возвращаем результат операции
  }

  Future<bool> restartEventAndUpdate(int eventId) async {
    bool success = await restartEvent(eventId);
    if (success) {
      setState(() {
        futureEvents = fetchEvents(); // Обновляем список событий после перезапуска
      });
    }
    return success; // Возвращаем результат операции
  }
  @override
  void initState() {
    super.initState();
    futureEvents = getEvents();
  }

  Future<void> refreshEvents() async {
    setState(() {
      futureEvents = getEvents();
    });
  }
  

  DateTime parseTime(String timeStr) {
    final format = DateFormat.jm();
    return format.parse(timeStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Events - ${DateFormat.yMMMd().format(DateTime.now())}"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarPage()),
              );
              refreshEvents(); // Обновите данные при возврате на эту страницу
            },

          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshEvents,
        child: FutureBuilder<List<Event>>(
          future: futureEvents,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Event>? events = snapshot.data;

              events!.sort((a, b) {
                if (a.status == b.status) {
                  DateTime aStart = DateTime.parse(a.start);
                  DateTime bStart = DateTime.parse(b.start);
                  return aStart.compareTo(bStart);
                }

                if (a.status == 'completed') {
                  return 1;
                } else if (b.status == 'completed') {
                  return -1;
                }

                return 0;
              });

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  Event event = events[index];
                  return EventTile(
                    key: UniqueKey(),
                    event: event,
                    isCompleted: event.status == 'completed',
                    completeEventAndUpdate: completeEventAndUpdate, // Передаем колбэк
                    restartEventAndUpdate: restartEventAndUpdate,
                    refreshEvents: () => refreshEvents(),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

class EventTile extends StatefulWidget {
  final Event event;
  final bool isCompleted;
  final Function(int) completeEventAndUpdate; // Добавляем параметр
  final Function(int) restartEventAndUpdate; // Добавляем параметр
  final void Function() refreshEvents;
  const EventTile({
    required Key key,
    required this.event,
    required this.completeEventAndUpdate, // Передаем функцию
    required this.restartEventAndUpdate,
    required this.refreshEvents,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  _EventTileState createState() => _EventTileState();



}

class _EventTileState extends State<EventTile> {
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    DateTime startTime = DateTime.parse(widget.event.start);
    DateTime endTime = DateTime.parse(widget.event.end);
    String formattedTime = '${DateFormat('hh:mma').format(startTime)} - ${DateFormat('hh:mma').format(endTime)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedTime,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isCompleted ? Colors.black.withOpacity(0.5) : Colors.black
              ),
            ),
            const SizedBox(height: 4),
          if(widget.event.status != "time_off") ...[
            Text("Job # ${widget.event.num}", style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold )),
            ...[
              if(widget.event.applianceName.isNotEmpty && widget.event.applianceBrand.isNotEmpty)
                Text("${widget.event.applianceName} / ${widget.event.applianceBrand}")
              else if(widget.event.applianceName.isNotEmpty)
                Text(widget.event.applianceName)
              else if(widget.event.applianceBrand.isNotEmpty)
                  Text(widget.event.applianceBrand),
            ],
            Text("By ${widget.event.company}", style: const TextStyle(fontStyle: FontStyle.italic)),
            if(widget.event.description.isNotEmpty)
              Text(widget.event.description),
            Text("Contact:  ${widget.event.contactName}",style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              child: Text(widget.event.contactAddress),
              onPressed: () {
                MapsLauncher.launchQuery(widget.event.contactAddress);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Flexible(
                  child: Text("${widget.event.phone1Desc}: ${widget.event.phone1}"),
                ),
                TextButton(
                  child: const Text("Call"),
                  onPressed: () async {
                    final call = Uri.parse('tel:${widget.event.phone1}');
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
                    final sms = Uri.parse('sms:${widget.event.phone1}');
                    if (await canLaunchUrl(sms)) {
                      launchUrl(sms);
                    } else {
                      throw 'Could not launch $sms';
                    }
                  },
                ),
              ],
            ),
            if(widget.event.phone2Desc.isNotEmpty && widget.event.phone2.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: Text("${widget.event.phone2Desc}: ${widget.event.phone2}"),
                  ),
                  TextButton(
                    child: const Text("Call"),
                    onPressed: () async {
                      final call = Uri.parse('tel:${widget.event.phone2}');
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
                      final sms = Uri.parse('sms:${widget.event.phone2}');
                      if (await canLaunchUrl(sms)) {
                        launchUrl(sms);
                      } else {
                        throw 'Could not launch $sms';
                      }
                    },
                  ),
                ],
              ),
            if(widget.event.phone3Desc.isNotEmpty && widget.event.phone3.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: Text("${widget.event.phone3Desc}: ${widget.event.phone3}"),
                  ),
                  TextButton(
                    child: const Text("Call"),
                    onPressed: () async {
                      final call = Uri.parse('tel:${widget.event.phone3}');
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
                      final sms = Uri.parse('sms:${widget.event.phone3}');
                      if (await canLaunchUrl(sms)) {
                        launchUrl(sms);
                      } else {
                        throw 'Could not launch $sms';
                      }
                    },
                  ),
                ],
              ),
            const Text("Assigned to:"),
            Text(widget.event.assignedTo.join(', ')),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,

    children: <Widget>[


      TextButton(
        onPressed: () async {
          setState(() {
            _isCompleted = !_isCompleted;
          });

          bool success;
          if (_isCompleted) {
            success = await widget.completeEventAndUpdate(int.parse(widget.event.id));
          } else {
            success = await widget.restartEventAndUpdate(int.parse(widget.event.id));
          }


          if (!success) {
            setState(() {
              _isCompleted = !_isCompleted;
            });
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _isCompleted ? Colors.red : Colors.green,
        ),
        child: Text(_isCompleted ? "RESTART" : "COMPLETE"),
      ),
      const SizedBox(width: 8), // Добавьте пространство между кнопками
      TextButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return EditEventDialog(
                event: widget.event,
                onDialogClosed: widget.refreshEvents,

              );
            },
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue, // Выберите цвет, который вам нравится
        ),
        child: const Text("EDIT"),
      ),
    ],
            ),
      ]
        else ...[
            if(widget.event.description.isNotEmpty)
              Text(widget.event.description),
            const Text("Assigned to:"),
            Text(widget.event.assignedTo.join(', ')),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return EditEventDialog(
                      event: widget.event,
                      onDialogClosed: widget.refreshEvents,

                    );
                  },
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // Выберите цвет, который вам нравится
              ),
              child: const Text("EDIT"),
            ),
          ],

          ],
        ),
      ),
    );
  }
}

