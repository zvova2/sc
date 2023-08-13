import 'dart:convert';
import 'package:http/http.dart' as http;
import 'event.dart'; // Убедитесь, что здесь определен ваш класс Event
import 'constants.dart'; // Убедитесь, что здесь определена константа baseUrl
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

Future<void> saveEvents(List<Event> events) async {
  final eventsBox = await Hive.openBox('events');
  final jsonEvents = json.encode(events.map((event) => event.toJson()).toList());
  await eventsBox.put('todayEvents', jsonEvents);
}

Future<List<Event>> loadEvents() async {
  final eventsBox = await Hive.openBox('events');
  final jsonEventsString = eventsBox.get('todayEvents') as String?;

  if (jsonEventsString != null) {
    final jsonEvents = json.decode(jsonEventsString) as List<dynamic>;
    return jsonEvents.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
  } else {
    return await fetchEvents();
  }
}

Future<List<Event>> getEvents() async {
  try {
    // Попытка загрузить события с сервера и сравнить с локальными
    List<Event> localEvents = await loadEvents();
    await fetchAndCompareEventsFromServer(localEvents);
    // Загрузка обновленных событий из локального хранилища
    return await loadEvents();
  } catch (e) {
    // Если произошла ошибка (например, нет интернета), загружаем из локального хранилища
    print('Failed to fetch or compare events from server, loading from local storage: $e');
    return await loadEvents();
  }
}



Future<void> fetchAndCompareEventsFromServer(List<Event> localEvents) async {
  try {
    List<Event> serverEvents = await fetchEvents();
    if (!areEventsEqual(localEvents, serverEvents)) {
      await saveEvents(serverEvents);
      print('Events updated from server.');
    }
  } catch (e) {
    print('Failed to fetch or compare events from server: $e');
  }
}

bool areEventsEqual(List<Event> events1, List<Event> events2) {
  return json.encode(events1) == json.encode(events2);
}

Future<List<Event>> fetchEvents() async {
  DateTime now = DateTime.now();
  String startDate = DateFormat("yyyy-MM-dd").format(now) + "T00:00:00-07:00";
  String endDate = DateFormat("yyyy-MM-dd").format(now) + "T23:59:59-07:00";

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString("user_id");
  String? jwt = prefs.getString("jwt");

  if (userId == null || jwt == null) {
    throw Exception('User ID or jwt not found');
  }

  final url = '$baseUrl/get_events_mobile.php?users=$userId&start=$startDate&end=$endDate';
  final headers = {
    'Authorization': 'Bearer $jwt',
  };

  final response = await http.get(Uri.parse(url), headers: headers);

  if (response.statusCode == 200) {
    List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((event) => Event.fromJson(event as Map<String, dynamic>)).toList();
  } else {
    throw Exception('Failed to load events');
  }
}

Future<List<Event>> fetchEventsForWeek(DateTime visibleStartDate, int numberOfDays) async {
  // Получение сегодняшней даты и даты через количество дней
  DateTime later = visibleStartDate.add(Duration(days: numberOfDays));

  String startDate = DateFormat("yyyy-MM-dd").format(visibleStartDate) + "T00:00:00-07:00";
  String endDate = DateFormat("yyyy-MM-dd").format(later) + "T23:59:59-07:00";

  // Получение сохраненного user id и токена
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString("user_id");
  String? jwt = prefs.getString("jwt");

  if (userId == null || jwt == null) {
    throw Exception('User ID or jwt not found');
  }

  // Строим URL с параметрами
  final url = '$baseUrl/get_events_mobile.php?users=$userId&start=$startDate&end=$endDate';

  // Создаем заголовок с токеном
  final headers = {
    'Authorization': 'Bearer $jwt',
  };

  final response = await http.get(Uri.parse(url), headers: headers);

  if (response.statusCode == 200) {
    // Если сервер возвращает ответ OK, парсим JSON
    List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((event) => Event.fromJson(event)).toList();
  } else {
    // Если ответ с ошибкой, бросаем исключение
    throw Exception('Failed to load events');
  }
}
