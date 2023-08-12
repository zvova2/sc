import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
part 'event.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class Event {
  @HiveField(1)
  final String id;
  @HiveField(2)
  final String serviceDescription;
  @HiveField(3)
  final String phone1Desc;
  @HiveField(4)
  final String phone2Desc;
  @HiveField(5)
  final String phone3Desc;
  @HiveField(6)
  final String status;
  @HiveField(7)
  final String start;
  @HiveField(8)
  final String end;
  @HiveField(9)
  final String applianceName;
  @HiveField(10)
  final String applianceBrand;
  @HiveField(11)
  final String company;
  @HiveField(12)
  final String num;
  @HiveField(13)
  final List<String> assignedTo;
  @HiveField(14)
  final String description;
  @HiveField(15)
  final String contactName;
  @HiveField(16)
  final String contactAddress;
  @HiveField(17)
  final String phone1;
  @HiveField(18)
  final String phone2;
  @HiveField(19)
  final String phone3;
  @HiveField(20)
  final String color;

  Event({
    required this.id,
    required this.serviceDescription,
    required this.phone1Desc,
    required this.phone2Desc,
    required this.phone3Desc,
    required this.status,
    required this.start,
    required this.end,
    required this.applianceName,
    required this.applianceBrand,
    required this.company,
    required this.num,
    required this.assignedTo,
    required this.description,
    required this.contactName,
    required this.contactAddress,
    required this.phone1,
    required this.phone2,
    required this.phone3,
    required this.color
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'].toString(),
      serviceDescription: json['service_description'] ?? '',
      phone1Desc: json['phone1_desc'] ?? '',
      phone2Desc: json['phone2_desc'] ?? '',
      phone3Desc: json['phone3_desc'] ?? '',
      status: json['status'] ?? '',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      applianceName: json['appliance_name'] ?? '',
      applianceBrand: json['appliance_brand'] ?? '',
      company: json['company'] ?? '',
      num: json['num'] ?? '',
      assignedTo: (json['assigned_to'] as List<dynamic>).map((e) => e.toString()).toList(),
      description: json['description'] ?? '',
      contactName: json['contact_name'] ?? '',
      contactAddress: json['full_address'] ?? '', // Предполагаем, что адрес берется из 'full_address'
      phone1: json['phone1'] ?? '',
      phone2: json['phone2'] ?? '',
      phone3: json['phone3'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_description': serviceDescription,
      'phone1_desc': phone1Desc,
      'phone2_desc': phone2Desc,
      'phone3_desc': phone3Desc,
      'status': status,
      'start': start,
      'end': end,
      'appliance_name': applianceName,
      'appliance_brand': applianceBrand,
      'company': company,
      'num': num,
      'assigned_to': assignedTo,
      'description': description,
      'contact_name': contactName,
      'full_address': contactAddress, // Предполагаем, что адрес записывается в 'full_address'
      'phone1': phone1,
      'phone2': phone2,
      'phone3': phone3,
      'color': color,
    };
  }

}

