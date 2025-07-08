import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:whaleskin/features/chat/chat_bloc.dart';
import 'package:whaleskin/data/repositories/chat_repository.dart';
import 'package:whaleskin/data/models/chat.dart';
import 'package:whaleskin/data/models/message.dart';

// Генерирует mock-объекты
@GenerateMocks([ChatRepository])
import 'chat_bloc_test.mocks.dart';

void main() {
  group('ChatBloc', () {
    late ChatBloc chatBloc;
    late MockChatRepository mockRepository;

    setUp(() {
      mockRepository = MockChatRepository();
      chatBloc = ChatBloc(mockRepository);
    });

    tearDown(() {
      chatBloc.close();
    });

    group('SendMessage', () {
      test('должен правильно обновлять историю сообщений', () async {
        // Arrange
        final testChat = Chat(
          id: 'test-chat-id',
          title: 'Test Chat',
          createdAt: DateTime.now(),
          lastMessageAt: DateTime.now(),
          isPinned: false,
          systemPrompt: null,
          temperature: 1.0,
          maxTokens: 2048,
          stopSequences: [],
          frequencyPenalty: 0.0,
          presencePenalty: 0.0,
          topP: 1.0,
          useDeepThink: false,
          useWebSearch: false,
        );

        final existingMessages = [
          Message.user(id: 'msg-1', content: 'Привет!', chatId: 'test-chat-id'),
          Message.assistant(
            id: 'msg-2',
            content: 'Привет! Как дела?',
            chatId: 'test-chat-id',
          ),
        ];

        final newMessages = [
          ...existingMessages,
          Message.user(
            id: 'msg-3',
            content: 'Хорошо, спасибо!',
            chatId: 'test-chat-id',
          ),
          Message.assistant(
            id: 'msg-4',
            content: 'Рад это слышать!',
            chatId: 'test-chat-id',
          ),
        ];

        // Mock setup
        when(mockRepository.initialize()).thenAnswer((_) async {});
        when(mockRepository.hasApiKey).thenAnswer((_) async => true);
        when(mockRepository.getAllChats()).thenReturn([testChat]);
        when(
          mockRepository.getMessagesForChat('test-chat-id'),
        ).thenReturn(existingMessages);

        // Симулируем успешную отправку
        when(
          mockRepository.sendMessage(
            chatId: anyNamed('chatId'),
            content: anyNamed('content'),
            systemPrompt: anyNamed('systemPrompt'),
            temperature: anyNamed('temperature'),
            maxTokens: anyNamed('maxTokens'),
            useDeepThink: anyNamed('useDeepThink'),
            useWebSearch: anyNamed('useWebSearch'),
          ),
        ).thenAnswer((_) async => 'Рад это слышать!');

        // После отправки возвращаем обновленные сообщения
        when(
          mockRepository.getMessagesForChat('test-chat-id'),
        ).thenReturn(newMessages);

        // Act & Assert
        await chatBloc.add(LoadChats());
        await chatBloc.add(SelectChat('test-chat-id'));

        expect(chatBloc.state, isA<ChatLoaded>());
        final initialState = chatBloc.state as ChatLoaded;
        expect(initialState.messages.length, 2);
        expect(initialState.isWaitingForResponse, false);

        // Отправляем новое сообщение
        chatBloc.add(SendMessage('Хорошо, спасибо!'));

        // Ждем обновления состояния
        await expectLater(
          chatBloc.stream,
          emitsInOrder([
            // Сначала состояние с сообщением пользователя и флагом ожидания
            predicate<ChatState>((state) {
              return state is ChatLoaded &&
                  state.messages.length == 3 &&
                  state.messages.last.content == 'Хорошо, спасибо!' &&
                  state.messages.last.role == 'user' &&
                  state.isWaitingForResponse == true;
            }),
            // Затем финальное состояние с ответом ассистента
            predicate<ChatState>((state) {
              return state is ChatLoaded &&
                  state.messages.length == 4 &&
                  state.messages.last.content == 'Рад это слышать!' &&
                  state.messages.last.role == 'assistant' &&
                  state.isWaitingForResponse == false;
            }),
          ]),
        );
      });
    });
  });
}
