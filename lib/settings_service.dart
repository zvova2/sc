import 'package:hive/hive.dart';


class SettingsService {
  final String _boxName = 'settings';
  final String _numberOfDaysKey = 'numberOfDays';
  final String _intervalValueKey = 'intervalValue';

  Future<void> saveNumberOfDays(int numberOfDays) async {
    var box = await Hive.openBox(_boxName);
    box.put(_numberOfDaysKey, numberOfDays);
  }

  Future<int> getNumberOfDays() async {
    var box = await Hive.openBox(_boxName);
    int numberOfDays = box.get(_numberOfDaysKey, defaultValue: 7);
    return numberOfDays;
  }

  Future<void> saveIntervalValue(String intervalValue) async {
    var box = await Hive.openBox(_boxName);
    box.put(_intervalValueKey, intervalValue);
  }

  Future<String> getIntervalValue() async {
    var box = await Hive.openBox(_boxName);
    String intervalValue = box.get(_intervalValueKey, defaultValue: '3');
    return intervalValue;
  }
}
