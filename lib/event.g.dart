// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 0;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[1] as String,
      serviceDescription: fields[2] as String,
      phone1Desc: fields[3] as String,
      phone2Desc: fields[4] as String,
      phone3Desc: fields[5] as String,
      status: fields[6] as String,
      start: fields[7] as String,
      end: fields[8] as String,
      applianceName: fields[9] as String,
      applianceBrand: fields[10] as String,
      company: fields[11] as String,
      num: fields[12] as String,
      assignedTo: (fields[13] as List).cast<String>(),
      description: fields[14] as String,
      contactName: fields[15] as String,
      contactAddress: fields[16] as String,
      phone1: fields[17] as String,
      phone2: fields[18] as String,
      phone3: fields[19] as String,
      color: fields[20] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(20)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.serviceDescription)
      ..writeByte(3)
      ..write(obj.phone1Desc)
      ..writeByte(4)
      ..write(obj.phone2Desc)
      ..writeByte(5)
      ..write(obj.phone3Desc)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.start)
      ..writeByte(8)
      ..write(obj.end)
      ..writeByte(9)
      ..write(obj.applianceName)
      ..writeByte(10)
      ..write(obj.applianceBrand)
      ..writeByte(11)
      ..write(obj.company)
      ..writeByte(12)
      ..write(obj.num)
      ..writeByte(13)
      ..write(obj.assignedTo)
      ..writeByte(14)
      ..write(obj.description)
      ..writeByte(15)
      ..write(obj.contactName)
      ..writeByte(16)
      ..write(obj.contactAddress)
      ..writeByte(17)
      ..write(obj.phone1)
      ..writeByte(18)
      ..write(obj.phone2)
      ..writeByte(19)
      ..write(obj.phone3)
      ..writeByte(20)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
      id: json['id'] as String,
      serviceDescription: json['serviceDescription'] as String,
      phone1Desc: json['phone1Desc'] as String,
      phone2Desc: json['phone2Desc'] as String,
      phone3Desc: json['phone3Desc'] as String,
      status: json['status'] as String,
      start: json['start'] as String,
      end: json['end'] as String,
      applianceName: json['applianceName'] as String,
      applianceBrand: json['applianceBrand'] as String,
      company: json['company'] as String,
      num: json['num'] as String,
      assignedTo: (json['assignedTo'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String,
      contactName: json['contactName'] as String,
      contactAddress: json['contactAddress'] as String,
      phone1: json['phone1'] as String,
      phone2: json['phone2'] as String,
      phone3: json['phone3'] as String,
      color: json['color'] as String,
    );

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'id': instance.id,
      'serviceDescription': instance.serviceDescription,
      'phone1Desc': instance.phone1Desc,
      'phone2Desc': instance.phone2Desc,
      'phone3Desc': instance.phone3Desc,
      'status': instance.status,
      'start': instance.start,
      'end': instance.end,
      'applianceName': instance.applianceName,
      'applianceBrand': instance.applianceBrand,
      'company': instance.company,
      'num': instance.num,
      'assignedTo': instance.assignedTo,
      'description': instance.description,
      'contactName': instance.contactName,
      'contactAddress': instance.contactAddress,
      'phone1': instance.phone1,
      'phone2': instance.phone2,
      'phone3': instance.phone3,
      'color': instance.color,
    };
