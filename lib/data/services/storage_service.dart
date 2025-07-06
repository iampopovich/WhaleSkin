import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message.dart';
import '../models/chat.dart';

class StorageService {
  static const String _apiKeyKey = 'deepseek_api_key';
  static const String _chatsBoxName = 'chats';
  static const String _messagesBoxName = 'messages';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static late Box<Chat> _chatsBox;
  static late Box<Message> _messagesBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Регистрируем адаптеры
    Hive.registerAdapter(ChatAdapter());
    Hive.registerAdapter(MessageAdapter());

    // Открываем боксы
    _chatsBox = await Hive.openBox<Chat>(_chatsBoxName);
    _messagesBox = await Hive.openBox<Message>(_messagesBoxName);
  }

  // API Key management
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }

  static Future<void> deleteApiKey() async {
    await _secureStorage.delete(key: _apiKeyKey);
  }

  static Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  // Chat management
  static Future<void> saveChat(Chat chat) async {
    await _chatsBox.put(chat.id, chat);
  }

  static Future<void> deleteChat(String chatId) async {
    await _chatsBox.delete(chatId);
    // Также удаляем все сообщения этого чата
    final messages = getMessagesForChat(chatId);
    for (final message in messages) {
      await _messagesBox.delete(message.id);
    }
  }

  static List<Chat> getAllChats() {
    return _chatsBox.values.toList();
  }

  static Chat? getChat(String chatId) {
    return _chatsBox.get(chatId);
  }

  static List<Chat> getChatsSorted() {
    final chats = getAllChats();
    chats.sort((a, b) {
      // Сначала закрепленные
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Потом по времени последнего сообщения
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });
    return chats;
  }

  // Message management
  static Future<void> saveMessage(Message message) async {
    await _messagesBox.put(message.id, message);
  }

  static Future<void> deleteMessage(String messageId) async {
    await _messagesBox.delete(messageId);
  }

  static List<Message> getMessagesForChat(String chatId) {
    return _messagesBox.values
        .where((message) => message.chatId == chatId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static List<Message> getAllMessages() {
    return _messagesBox.values.toList();
  }

  // Utility methods
  static Future<void> clearAllData() async {
    await _chatsBox.clear();
    await _messagesBox.clear();
    await deleteApiKey();
  }

  static Future<void> close() async {
    await _chatsBox.close();
    await _messagesBox.close();
  }
}
