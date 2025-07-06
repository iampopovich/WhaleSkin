// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 1;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime,
      lastMessageAt: fields[3] as DateTime,
      isPinned: fields[4] as bool,
      systemPrompt: fields[5] as String?,
      temperature: fields[6] as double,
      maxTokens: fields[7] as int,
      stopSequences: (fields[8] as List).cast<String>(),
      frequencyPenalty: fields[9] as double,
      presencePenalty: fields[10] as double,
      topP: fields[11] as double,
      useDeepThink: fields[12] as bool,
      useWebSearch: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.lastMessageAt)
      ..writeByte(4)
      ..write(obj.isPinned)
      ..writeByte(5)
      ..write(obj.systemPrompt)
      ..writeByte(6)
      ..write(obj.temperature)
      ..writeByte(7)
      ..write(obj.maxTokens)
      ..writeByte(8)
      ..write(obj.stopSequences)
      ..writeByte(9)
      ..write(obj.frequencyPenalty)
      ..writeByte(10)
      ..write(obj.presencePenalty)
      ..writeByte(11)
      ..write(obj.topP)
      ..writeByte(12)
      ..write(obj.useDeepThink)
      ..writeByte(13)
      ..write(obj.useWebSearch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chat _$ChatFromJson(Map<String, dynamic> json) => Chat(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      systemPrompt: json['systemPrompt'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 1.0,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2048,
      stopSequences: (json['stopSequences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      useDeepThink: json['useDeepThink'] as bool? ?? false,
      useWebSearch: json['useWebSearch'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatToJson(Chat instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt.toIso8601String(),
      'isPinned': instance.isPinned,
      'systemPrompt': instance.systemPrompt,
      'temperature': instance.temperature,
      'maxTokens': instance.maxTokens,
      'stopSequences': instance.stopSequences,
      'frequencyPenalty': instance.frequencyPenalty,
      'presencePenalty': instance.presencePenalty,
      'topP': instance.topP,
      'useDeepThink': instance.useDeepThink,
      'useWebSearch': instance.useWebSearch,
    };
