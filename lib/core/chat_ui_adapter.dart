import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import '../data/models/message.dart' as app_models;

class ChatUIAdapter {
  // Convert app Message to flutter_chat_core TextMessage
  static chat_core.TextMessage toFlutterChatMessage(
    app_models.Message message,
  ) {
    final isUser = message.role == 'user';

    return chat_core.TextMessage(
      authorId: isUser ? 'user' : 'assistant',
      createdAt: message.timestamp,
      id: message.id,
      text: message.content,
    );
  }

  // Convert flutter_chat_core message to app Message
  static app_models.Message fromFlutterChatMessage(
    chat_core.Message message,
    String chatId,
  ) {
    if (message is chat_core.TextMessage) {
      return app_models.Message(
        id: message.id,
        content: message.text,
        role: message.authorId == 'user' ? 'user' : 'assistant',
        timestamp: message.createdAt ?? DateTime.now(),
        chatId: chatId,
      );
    }

    // Fallback for other message types
    return app_models.Message(
      id: message.id,
      content: message.toString(),
      role: message.authorId == 'user' ? 'user' : 'assistant',
      timestamp: message.createdAt ?? DateTime.now(),
      chatId: chatId,
    );
  }

  // Convert list of app Messages to flutter_chat_core Messages
  static List<chat_core.Message> toFlutterChatMessages(
    List<app_models.Message> messages,
  ) {
    return messages.map((message) => toFlutterChatMessage(message)).toList();
  }

  // Define users for the chat
  static const chat_core.User currentUser = chat_core.User(id: 'user');
  static const chat_core.User aiUser = chat_core.User(id: 'assistant');
}
