import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Message {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final String role; // 'user' or 'assistant'

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String chatId;

  const Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    required this.chatId,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  factory Message.user({
    required String id,
    required String content,
    required String chatId,
  }) {
    return Message(
      id: id,
      content: content,
      role: 'user',
      timestamp: DateTime.now(),
      chatId: chatId,
    );
  }

  factory Message.assistant({
    required String id,
    required String content,
    required String chatId,
  }) {
    return Message(
      id: id,
      content: content,
      role: 'assistant',
      timestamp: DateTime.now(),
      chatId: chatId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
