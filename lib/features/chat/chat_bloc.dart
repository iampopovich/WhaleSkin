import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../../data/repositories/chat_repository.dart';

// Events
abstract class ChatEvent {}

class LoadChats extends ChatEvent {}

class CreateChat extends ChatEvent {
  final String? title;
  CreateChat({this.title});
}

class SelectChat extends ChatEvent {
  final String chatId;
  SelectChat(this.chatId);
}

class SendMessage extends ChatEvent {
  final String content;
  SendMessage(this.content);
}

class ToggleChatPin extends ChatEvent {
  final String chatId;
  ToggleChatPin(this.chatId);
}

class DeleteChat extends ChatEvent {
  final String chatId;
  DeleteChat(this.chatId);
}

class SetApiKey extends ChatEvent {
  final String apiKey;
  SetApiKey(this.apiKey);
}

class ExportChat extends ChatEvent {
  final String chatId;
  final String format; // 'json', 'markdown', 'pdf'
  ExportChat(this.chatId, this.format);
}

class UpdateChatSettings extends ChatEvent {
  final String chatId;
  final Map<String, dynamic> updates;
  UpdateChatSettings(this.chatId, this.updates);
}

class RenameChat extends ChatEvent {
  final String chatId;
  final String newTitle;
  RenameChat(this.chatId, this.newTitle);
}

class TestApiKey extends ChatEvent {
  final String apiKey;
  TestApiKey(this.apiKey);
}

class CancelMessage extends ChatEvent {}

// States
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Chat> chats;
  final Chat? selectedChat;
  final List<Message> messages;
  final bool hasApiKey;
  final bool isWaitingForResponse;

  ChatLoaded({
    required this.chats,
    this.selectedChat,
    required this.messages,
    required this.hasApiKey,
    this.isWaitingForResponse = false,
  });

  ChatLoaded copyWith({
    List<Chat>? chats,
    Chat? selectedChat,
    List<Message>? messages,
    bool? hasApiKey,
    bool? isWaitingForResponse,
  }) {
    return ChatLoaded(
      chats: chats ?? this.chats,
      selectedChat: selectedChat ?? this.selectedChat,
      messages: messages ?? this.messages,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      isWaitingForResponse: isWaitingForResponse ?? this.isWaitingForResponse,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatLoaded &&
          runtimeType == other.runtimeType &&
          _listEquals(chats, other.chats) &&
          selectedChat == other.selectedChat &&
          _listEquals(messages, other.messages) &&
          hasApiKey == other.hasApiKey &&
          isWaitingForResponse == other.isWaitingForResponse;

  @override
  int get hashCode => Object.hash(
    chats.length,
    selectedChat,
    messages.length,
    hasApiKey,
    isWaitingForResponse,
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

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

class MessageSending extends ChatLoaded {
  MessageSending({
    required super.chats,
    super.selectedChat,
    required super.messages,
    required super.hasApiKey,
  });
}

class ChatExporting extends ChatLoaded {
  ChatExporting({
    required super.chats,
    super.selectedChat,
    required super.messages,
    required super.hasApiKey,
  });
}

class ChatExported extends ChatLoaded {
  final String filePath;
  final String format;

  ChatExported({
    required this.filePath,
    required this.format,
    required super.chats,
    super.selectedChat,
    required super.messages,
    required super.hasApiKey,
  });
}

class ApiKeyTesting extends ChatState {}

class ApiKeyTestSuccess extends ChatState {
  final String apiKey;
  ApiKeyTestSuccess(this.apiKey);
}

class ApiKeyTestFailed extends ChatState {
  final String message;
  ApiKeyTestFailed(this.message);
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<CreateChat>(_onCreateChat);
    on<SelectChat>(_onSelectChat);
    on<SendMessage>(_onSendMessage);
    on<ToggleChatPin>(_onToggleChatPin);
    on<DeleteChat>(_onDeleteChat);
    on<SetApiKey>(_onSetApiKey);
    on<ExportChat>(_onExportChat);
    on<UpdateChatSettings>(_onUpdateChatSettings);
    on<RenameChat>(_onRenameChat);
    on<TestApiKey>(_onTestApiKey);
    on<CancelMessage>(_onCancelMessage);
  }

  Future<void> _onLoadChats(LoadChats event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      await _repository.initialize();
      final chats = _repository.getAllChats();
      final hasApiKey = await _repository.hasApiKey;

      emit(
        ChatLoaded(
          chats: chats,
          messages: [],
          hasApiKey: hasApiKey,
          isWaitingForResponse: false,
        ),
      );
    } catch (e) {
      emit(ChatError('Ошибка загрузки чатов: $e'));
    }
  }

  Future<void> _onCreateChat(CreateChat event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      final newChat = await _repository.createChat(title: event.title);

      final updatedChats = _repository.getAllChats();
      emit(
        currentState.copyWith(
          chats: updatedChats,
          selectedChat: newChat,
          messages: [],
        ),
      );
    } catch (e) {
      emit(ChatError('Ошибка создания чата: $e'));
    }
  }

  Future<void> _onSelectChat(SelectChat event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      final chat = currentState.chats.firstWhere((c) => c.id == event.chatId);
      final messages = _repository.getMessagesForChat(event.chatId);

      emit(currentState.copyWith(selectedChat: chat, messages: messages));
    } catch (e) {
      emit(ChatError('Ошибка выбора чата: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    if (currentState.selectedChat == null ||
        currentState.isWaitingForResponse) {
      return;
    }

    // Создаем сообщение пользователя
    final userMessage = Message.user(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.content,
      chatId: currentState.selectedChat!.id,
    );

    // Добавляем сообщение пользователя сразу в локальный список
    final updatedMessages = [...currentState.messages, userMessage];

    // Обновляем состояние с новым сообщением и флагом ожидания
    emit(
      currentState.copyWith(
        messages: updatedMessages,
        isWaitingForResponse: true,
      ),
    );

    try {
      // Отправляем сообщение через репозиторий
      await _repository.sendMessage(
        chatId: currentState.selectedChat!.id,
        content: event.content,
        systemPrompt: currentState.selectedChat!.systemPrompt,
        temperature: currentState.selectedChat!.temperature,
        maxTokens: currentState.selectedChat!.maxTokens,
        useDeepThink: currentState.selectedChat!.useDeepThink,
        useWebSearch: currentState.selectedChat!.useWebSearch,
      );

      // Получаем обновленные сообщения (включая ответ ИИ)
      final finalMessages = _repository.getMessagesForChat(
        currentState.selectedChat!.id,
      );
      final updatedChats = _repository.getAllChats();

      emit(
        ChatLoaded(
          chats: updatedChats,
          selectedChat: currentState.selectedChat,
          messages: finalMessages,
          hasApiKey: currentState.hasApiKey,
          isWaitingForResponse: false,
        ),
      );
    } catch (e) {
      // В случае ошибки возвращаем состояние без ответа ИИ
      emit(
        currentState.copyWith(
          messages: updatedMessages,
          isWaitingForResponse: false,
        ),
      );
      emit(ChatError('Ошибка отправки сообщения: $e'));
    }
  }

  Future<void> _onToggleChatPin(
    ToggleChatPin event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _repository.toggleChatPin(event.chatId);
      final updatedChats = _repository.getAllChats();

      emit(currentState.copyWith(chats: updatedChats));
    } catch (e) {
      emit(ChatError('Ошибка закрепления чата: $e'));
    }
  }

  Future<void> _onDeleteChat(DeleteChat event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _repository.deleteChat(event.chatId);
      final updatedChats = _repository.getAllChats();

      Chat? newSelectedChat = currentState.selectedChat;
      List<Message> newMessages = currentState.messages;

      // Если удаленный чат был выбран, сбрасываем выбор
      if (currentState.selectedChat?.id == event.chatId) {
        newSelectedChat = null;
        newMessages = [];
      }

      emit(
        currentState.copyWith(
          chats: updatedChats,
          selectedChat: newSelectedChat,
          messages: newMessages,
        ),
      );
    } catch (e) {
      emit(ChatError('Ошибка удаления чата: $e'));
    }
  }

  Future<void> _onSetApiKey(SetApiKey event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final success = await _repository.setApiKey(event.apiKey);
      if (success) {
        final chats = _repository.getAllChats();
        emit(
          ChatLoaded(
            chats: chats,
            messages: [],
            hasApiKey: true,
            isWaitingForResponse: false,
          ),
        );
      } else {
        emit(ChatError('Неверный API ключ'));
      }
    } catch (e) {
      emit(ChatError('Ошибка сохранения API ключа: $e'));
    }
  }

  Future<void> _onExportChat(ExportChat event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;

    emit(
      ChatExporting(
        chats: currentState.chats,
        selectedChat: currentState.selectedChat,
        messages: currentState.messages,
        hasApiKey: currentState.hasApiKey,
      ),
    );

    try {
      String filePath;

      switch (event.format) {
        case 'json':
          filePath = await _repository.exportChatToJsonFile(event.chatId);
          break;
        case 'markdown':
          filePath = await _repository.exportChatToMarkdownFile(event.chatId);
          break;
        case 'pdf':
          filePath = await _repository.exportChatToPdfFile(event.chatId);
          break;
        default:
          throw Exception('Неподдерживаемый формат экспорта');
      }

      emit(
        ChatExported(
          filePath: filePath,
          format: event.format,
          chats: currentState.chats,
          selectedChat: currentState.selectedChat,
          messages: currentState.messages,
          hasApiKey: currentState.hasApiKey,
        ),
      );
    } catch (e) {
      emit(ChatError('Ошибка экспорта: $e'));
    }
  }

  Future<void> _onUpdateChatSettings(
    UpdateChatSettings event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _repository.updateChatSettings(event.chatId, event.updates);

      final updatedChats = _repository.getAllChats();
      final updatedSelectedChat = updatedChats.firstWhere(
        (chat) => chat.id == event.chatId,
        orElse: () => currentState.selectedChat!,
      );

      emit(
        currentState.copyWith(
          chats: updatedChats,
          selectedChat: updatedSelectedChat,
        ),
      );
    } catch (e) {
      emit(ChatError('Ошибка обновления настроек чата: $e'));
    }
  }

  Future<void> _onRenameChat(RenameChat event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;

    try {
      final currentState = state as ChatLoaded;
      await _repository.renameChat(event.chatId, event.newTitle);

      final updatedChats = _repository.getAllChats();
      final updatedSelectedChat = currentState.selectedChat?.id == event.chatId
          ? updatedChats.firstWhere((chat) => chat.id == event.chatId)
          : currentState.selectedChat;

      emit(
        currentState.copyWith(
          chats: updatedChats,
          selectedChat: updatedSelectedChat,
        ),
      );
    } catch (e) {
      emit(ChatError('Ошибка переименования чата: $e'));
    }
  }

  Future<void> _onTestApiKey(TestApiKey event, Emitter<ChatState> emit) async {
    emit(ApiKeyTesting());
    try {
      final isValid = await _repository.testApiKey(event.apiKey);
      if (isValid) {
        emit(ApiKeyTestSuccess(event.apiKey));
      } else {
        emit(ApiKeyTestFailed('Неверный API ключ или нет доступа к API'));
      }
    } catch (e) {
      emit(ApiKeyTestFailed('Ошибка подключения к серверу DeepSeek'));
    }
  }

  Future<void> _onCancelMessage(
    CancelMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    if (!currentState.isWaitingForResponse) return;

    // Просто убираем флаг ожидания ответа
    emit(currentState.copyWith(isWaitingForResponse: false));
  }
}
