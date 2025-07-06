import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Chat {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime lastMessageAt;

  @HiveField(4)
  final bool isPinned;

  // Chat behavior settings (embedded bot settings)
  @HiveField(5)
  final String? systemPrompt;

  @HiveField(6)
  final double temperature;

  @HiveField(7)
  final int maxTokens;

  @HiveField(8)
  final List<String> stopSequences;

  @HiveField(9)
  final double frequencyPenalty;

  @HiveField(10)
  final double presencePenalty;

  @HiveField(11)
  final double topP;

  @HiveField(12)
  final bool useDeepThink;

  @HiveField(13)
  final bool useWebSearch;

  const Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    this.isPinned = false,
    this.systemPrompt,
    this.temperature = 1.0,
    this.maxTokens = 2048,
    this.stopSequences = const [],
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.topP = 1.0,
    this.useDeepThink = false,
    this.useWebSearch = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);
  Map<String, dynamic> toJson() => _$ChatToJson(this);

  Chat copyWith({
    String? title,
    DateTime? lastMessageAt,
    bool? isPinned,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    List<String>? stopSequences,
    double? frequencyPenalty,
    double? presencePenalty,
    double? topP,
    bool? useDeepThink,
    bool? useWebSearch,
  }) {
    return Chat(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isPinned: isPinned ?? this.isPinned,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      stopSequences: stopSequences ?? this.stopSequences,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      topP: topP ?? this.topP,
      useDeepThink: useDeepThink ?? this.useDeepThink,
      useWebSearch: useWebSearch ?? this.useWebSearch,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          createdAt == other.createdAt &&
          lastMessageAt == other.lastMessageAt &&
          isPinned == other.isPinned &&
          systemPrompt == other.systemPrompt &&
          temperature == other.temperature &&
          maxTokens == other.maxTokens &&
          useDeepThink == other.useDeepThink &&
          useWebSearch == other.useWebSearch &&
          frequencyPenalty == other.frequencyPenalty &&
          presencePenalty == other.presencePenalty &&
          topP == other.topP &&
          _listEquals(stopSequences, other.stopSequences);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createdAt,
    lastMessageAt,
    isPinned,
    systemPrompt,
    temperature,
    maxTokens,
    useDeepThink,
    useWebSearch,
    frequencyPenalty,
    presencePenalty,
    topP,
    stopSequences,
  );

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
