import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/message.dart';
import '../services/deepseek_api_service.dart';
import '../services/storage_service.dart';
import '../services/export_service.dart';

class ChatRepository {
  late DeepSeekApiService _apiService;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await StorageService.init();

    final apiKey = await StorageService.getApiKey();
    if (apiKey != null) {
      _apiService = DeepSeekApiService(apiKey: apiKey);
    }

    _isInitialized = true;
  }

  Future<bool> setApiKey(String apiKey) async {
    try {
      final testService = DeepSeekApiService(apiKey: apiKey);
      final isValid = await testService.validateApiKey();

      if (isValid) {
        await StorageService.saveApiKey(apiKey);
        _apiService = testService;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> get hasApiKey async =>
      _isInitialized && await StorageService.hasApiKey();

  // Test API key validity
  Future<bool> testApiKey(String apiKey) async {
    final tempService = DeepSeekApiService(apiKey: apiKey);
    return await tempService.testApiKey();
  }

  // Chat operations
  Future<Chat> createChat({String? title}) async {
    final chatId = DateTime.now().millisecondsSinceEpoch.toString();
    final chat = Chat(
      id: chatId,
      title: title ?? 'Новый чат',
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
    );

    await StorageService.saveChat(chat);
    return chat;
  }

  List<Chat> getAllChats() {
    return StorageService.getChatsSorted();
  }

  Future<void> updateChat(Chat chat) async {
    await StorageService.saveChat(chat);
  }

  Future<void> deleteChat(String chatId) async {
    await StorageService.deleteChat(chatId);
  }

  Future<Chat> toggleChatPin(String chatId) async {
    final chat = StorageService.getChat(chatId);
    if (chat != null) {
      final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
      await StorageService.saveChat(updatedChat);
      return updatedChat;
    }
    throw Exception('Chat not found');
  }

  // Message operations
  List<Message> getMessagesForChat(String chatId) {
    return StorageService.getMessagesForChat(chatId);
  }

  Future<String> sendMessage({
    required String chatId,
    required String content,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    bool? useDeepThink,
    bool? useWebSearch,
  }) async {
    if (!_isInitialized) {
      throw Exception('Repository not initialized');
    }

    // Получаем текущую историю сообщений для контекста
    final existingMessages = getMessagesForChat(chatId);

    // Создаем новое сообщение пользователя для API
    final newUserMessage = {'role': 'user', 'content': content};

    // Формируем полную историю для API
    final apiMessages = [
      ...existingMessages.map(
        (msg) => {'role': msg.role, 'content': msg.content},
      ),
      newUserMessage,
    ];

    // Сохраняем сообщение пользователя в локальной базе
    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final userMessage = Message.user(
      id: userMessageId,
      content: content,
      chatId: chatId,
    );
    await StorageService.saveMessage(userMessage);

    try {
      // Определяем модель на основе настроек чата
      final model = (useDeepThink == true)
          ? 'deepseek-reasoner'
          : 'deepseek-chat';

      // Отправляем запрос к API с полной историей
      final response = await _apiService.sendChatMessage(
        messages: apiMessages,
        model: model,
        systemPrompt: systemPrompt,
        temperature: temperature ?? 1.0,
        maxTokens: maxTokens ?? 2048,
        stopSequences: const [],
        frequencyPenalty: 0.0,
        presencePenalty: 0.0,
        topP: 1.0,
        useWebSearch: useWebSearch ?? false,
      );

      // Сохраняем ответ ассистента
      final assistantMessageId = (DateTime.now().millisecondsSinceEpoch + 1)
          .toString();
      final assistantMessage = Message.assistant(
        id: assistantMessageId,
        content: response,
        chatId: chatId,
      );
      await StorageService.saveMessage(assistantMessage);

      // Обновляем время последнего сообщения в чате
      final chat = StorageService.getChat(chatId);
      if (chat != null) {
        final updatedChat = chat.copyWith(lastMessageAt: DateTime.now());
        await StorageService.saveChat(updatedChat);

        // Автоматически генерируем название для чата, если это первое сообщение пользователя
        final allMessages = getMessagesForChat(chatId);
        final userMessages = allMessages
            .where((m) => m.role == 'user')
            .toList();
        if (userMessages.length == 1 && chat.title == 'Новый чат') {
          try {
            final newTitle = await _generateChatTitle(content);
            final renamedChat = updatedChat.copyWith(title: newTitle);
            await StorageService.saveChat(renamedChat);
          } catch (e) {
            debugPrint('Failed to generate chat title: $e');
          }
        }
      }

      return response;
    } catch (e) {
      // В случае ошибки удаляем сообщение пользователя
      await StorageService.deleteMessage(userMessageId);
      rethrow;
    }
  }

  // Export operations
  Map<String, dynamic> exportChatToJson(String chatId) {
    final chat = StorageService.getChat(chatId);
    final messages = getMessagesForChat(chatId);

    if (chat == null) {
      throw Exception('Chat not found');
    }

    return {
      'chat': chat.toJson(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  String exportChatToMarkdown(String chatId) {
    final chat = StorageService.getChat(chatId);
    final messages = getMessagesForChat(chatId);

    if (chat == null) {
      throw Exception('Chat not found');
    }

    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('');
    buffer.writeln('Создан: ${chat.createdAt.toString()}');
    buffer.writeln('Экспортирован: ${DateTime.now().toString()}');
    buffer.writeln('');

    for (final message in messages) {
      buffer.writeln(
        '## ${message.role == 'user' ? 'Пользователь' : 'Ассистент'}',
      );
      buffer.writeln('');
      buffer.writeln(message.content);
      buffer.writeln('');
      buffer.writeln('*${message.timestamp.toString()}*');
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<String> exportChatToJsonFile(String chatId) async {
    final chat = StorageService.getChat(chatId);
    final messages = getMessagesForChat(chatId);

    if (chat == null) {
      throw Exception('Chat not found');
    }

    return await ExportService.exportChatToJson(chat, messages);
  }

  Future<String> exportChatToMarkdownFile(String chatId) async {
    final chat = StorageService.getChat(chatId);
    final messages = getMessagesForChat(chatId);

    if (chat == null) {
      throw Exception('Chat not found');
    }

    return await ExportService.exportChatToMarkdown(chat, messages);
  }

  Future<String> exportChatToPdfFile(String chatId) async {
    final chat = StorageService.getChat(chatId);
    final messages = getMessagesForChat(chatId);

    if (chat == null) {
      throw Exception('Chat not found');
    }

    return await ExportService.exportChatToPdf(chat, messages);
  }

  // Update chat settings
  Future<void> updateChatSettings(
    String chatId,
    Map<String, dynamic> updates,
  ) async {
    final chat = StorageService.getChat(chatId);
    if (chat == null) {
      throw Exception('Chat not found');
    }

    final updatedChat = chat.copyWith(
      systemPrompt: updates['systemPrompt'] as String?,
      temperature: updates['temperature'] as double?,
      maxTokens: updates['maxTokens'] as int?,
      useDeepThink: updates['useDeepThink'] as bool?,
      useWebSearch: updates['useWebSearch'] as bool?,
      frequencyPenalty: updates['frequencyPenalty'] as double?,
      presencePenalty: updates['presencePenalty'] as double?,
      topP: updates['topP'] as double?,
      stopSequences: updates['stopSequences'] as List<String>?,
    );

    await StorageService.saveChat(updatedChat);
  }

  // Rename chat
  Future<void> renameChat(String chatId, String newTitle) async {
    final chat = StorageService.getChat(chatId);
    if (chat == null) {
      throw Exception('Chat not found');
    }

    final updatedChat = chat.copyWith(title: newTitle);
    await StorageService.saveChat(updatedChat);
  }

  // Generate title from first message
  Future<String> _generateChatTitle(String firstMessage) async {
    try {
      final apiKey = await StorageService.getApiKey();
      if (apiKey == null) {
        return 'Новый чат';
      }

      final client = http.Client();
      final response = await client.post(
        Uri.parse('https://api.deepseek.com/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Создай краткое название (не более 4-5 слов) для чата на основе первого сообщения пользователя. Отвечай только названием, без дополнительного текста.',
            },
            {'role': 'user', 'content': firstMessage},
          ],
          'max_tokens': 20,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['choices'][0]['message']['content']
            .toString()
            .trim();
        return title.isNotEmpty ? title : 'Новый чат';
      }
    } catch (e) {
      debugPrint('Error generating title: $e');
    }

    return 'Новый чат';
  }

  // Utility methods
  Future<void> clearAllData() async {
    await StorageService.clearAllData();
    _isInitialized = false;
  }
}
