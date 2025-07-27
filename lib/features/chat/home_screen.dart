import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../../core/chat_ui_adapter.dart';
import '../../core/theme_provider.dart';
import '../../data/models/message.dart' as app_models;
import '../../data/models/chat.dart' as app_chat;
import '../chat/chat_bloc.dart';
import '../export/export.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final chat_core.InMemoryChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = chat_core.InMemoryChatController();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleMessageSend(String text) {
    final bloc = context.read<ChatBloc>();
    bloc.add(SendMessage(text));
  }

  Future<chat_core.User?> _resolveUser(String id) async {
    switch (id) {
      case 'user':
        return ChatUIAdapter.currentUser;
      case 'assistant':
        return ChatUIAdapter.aiUser;
      default:
        return null;
    }
  }

  void _syncMessagesWithController(List<app_models.Message> messages) {
    final chatMessages = ChatUIAdapter.toFlutterChatMessages(messages);

    // Простое обновление: очищаем и добавляем заново (можно оптимизировать)
    final currentMessageIds = _chatController.messages.map((m) => m.id).toSet();
    final newMessageIds = chatMessages.map((m) => m.id).toSet();

    // Удаляем сообщения, которых больше нет
    for (final message in _chatController.messages.toList()) {
      if (!newMessageIds.contains(message.id)) {
        _chatController.removeMessage(message);
      }
    }

    // Добавляем новые сообщения
    for (final message in chatMessages) {
      if (!currentMessageIds.contains(message.id)) {
        _chatController.insertMessage(message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          // Можно добавить другие слушатели, если нужно
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F9CF9)),
              );
            }

            if (state is ChatLoaded) {
              // Синхронизируем сообщения с контроллером при изменении состояния
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncMessagesWithController(state.messages);
              });

              return Row(
                children: [
                  // Боковая панель с чатами (адаптивная)
                  MediaQuery.of(context).size.width > 800
                      ? Container(
                          width: 300,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border(
                              right: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: _buildChatSidebar(state),
                        )
                      : const SizedBox.shrink(),
                  // Основная область чата
                  Expanded(
                    child: state.selectedChat != null
                        ? _buildChatArea(state)
                        : _buildEmptyState(),
                  ),
                ],
              );
            }

            if (state is ChatError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return const Center(
              child: Text(
                'Инициализация...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          },
        ),
      ),
      // Плавающая кнопка для мобильных устройств
      floatingActionButton: MediaQuery.of(context).size.width <= 800
          ? BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoaded) {
                  return FloatingActionButton(
                    onPressed: () {
                      _showMobileChatList(context, state);
                    },
                    backgroundColor: const Color(0xFF4F9CF9),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            )
          : null,
    );
  }

  void _showMobileChatList(BuildContext context, ChatLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A3A),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _buildChatSidebar(state),
      ),
    );
  }

  Widget _buildChatSidebar(ChatLoaded state) {
    return Column(
      children: [
        // Заголовок и кнопка создания чата
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Чаты',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  try {
                    final themeManager = ThemeProvider.themeManagerOf(context);
                    themeManager.toggleTheme();
                  } catch (e) {
                    // Fallback - попробуем найти провайдер другим способом
                    final themeProvider = ThemeProvider.of(context);
                    if (themeProvider != null) {
                      themeProvider.themeManager.toggleTheme();
                    }
                  }
                },
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: const Color(0xFF4F9CF9),
                ),
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Светлая тема'
                    : 'Темная тема',
              ),
              IconButton(
                onPressed: () {
                  context.read<ChatBloc>().add(CreateChat());
                },
                icon: const Icon(Icons.add, color: Color(0xFF4F9CF9)),
                tooltip: 'Новый чат (Ctrl+N)',
              ),
            ],
          ),
        ),
        // Поиск чатов
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: TextField(
            onChanged: (value) {
              // TODO: Implement chat search filtering
            },
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: 'Поиск чатов...',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF64748B),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF64748B),
              ),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        // Список чатов
        Expanded(
          child: ListView.builder(
            itemCount: state.chats.length,
            itemBuilder: (context, index) {
              final chat = state.chats[index];
              final isSelected = state.selectedChat?.id == chat.id;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4F9CF9).withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF4F9CF9), width: 1)
                      : null,
                ),
                child: ListTile(
                  onTap: () {
                    context.read<ChatBloc>().add(SelectChat(chat.id));
                  },
                  leading: Icon(
                    chat.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
                    color: chat.isPinned
                        ? const Color(0xFF4F9CF9)
                        : const Color(0xFF64748B),
                  ),
                  title: Text(
                    chat.title,
                    style: TextStyle(
                      color: isSelected
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1E293B))
                          : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569)),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatTime(chat.lastMessageAt),
                    style: TextStyle(
                      color: isSelected
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B))
                          : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                      fontSize: 12,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: isSelected
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B))
                          : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                    ),
                    onSelected: (action) {
                      switch (action) {
                        case 'pin':
                          context.read<ChatBloc>().add(ToggleChatPin(chat.id));
                          break;
                        case 'delete':
                          context.read<ChatBloc>().add(DeleteChat(chat.id));
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              chat.isPinned
                                  ? Icons.push_pin_outlined
                                  : Icons.push_pin,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(chat.isPinned ? 'Открепить' : 'Закрепить'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatArea(ChatLoaded state) {
    return Column(
      children: [
        // Заголовок чата
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A3A),
            border: Border(
              bottom: BorderSide(color: Color(0xFF3A3A4A), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (state.selectedChat != null) {
                      _showRenameChatDialog(context, state.selectedChat!);
                    }
                  },
                  child: Text(
                    state.selectedChat?.title ?? 'Чат',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                  onSelected: (action) {
                    if (state.selectedChat != null) {
                      switch (action) {
                        case 'settings':
                          _showChatSettings(context, state.selectedChat!);
                          break;
                        case 'export_json':
                        case 'export_md':
                        case 'export_pdf':
                          _showExportDialog(context, state.selectedChat!);
                          break;
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 20),
                          SizedBox(width: 8),
                          Text('Настройки чата'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'export_json',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text('Экспорт в JSON'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export_md',
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 20),
                          SizedBox(width: 8),
                          Text('Экспорт в Markdown'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export_pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 20),
                          SizedBox(width: 8),
                          Text('Экспорт в PDF'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Область чата с использованием flutter_chat_ui
        Expanded(
          child: Column(
            children: [
              // Индикатор ожидания ответа
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: state.isWaitingForResponse ? 60 : 0,
                child: state.isWaitingForResponse
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3A3A4A),
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF4A4A5A),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4F9CF9),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Генерирую ответ...',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                context.read<ChatBloc>().add(CancelMessage());
                              },
                              child: const Text(
                                'Отменить',
                                style: TextStyle(color: Color(0xFF4F9CF9)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              // Сам чат
              Expanded(
                child: Chat(
                  chatController: _chatController,
                  currentUserId: 'user',
                  onMessageSend: state.isWaitingForResponse
                      ? null
                      : _handleMessageSend,
                  resolveUser: _resolveUser,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFF64748B)),
          SizedBox(height: 16),
          Text(
            'Выберите чат или создайте новый',
            style: TextStyle(fontSize: 18, color: Color(0xFF94A3B8)),
          ),
          SizedBox(height: 8),
          Text(
            'Начните общение с DeepSeek AI',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}мин назад';
    } else {
      return 'только что';
    }
  }

  void _showChatSettings(BuildContext context, app_chat.Chat chat) {
    showDialog(
      context: context,
      builder: (context) => _ChatSettingsDialog(
        chat: chat,
        chatBloc: this.context.read<ChatBloc>(),
      ),
    );
  }

  void _showRenameChatDialog(BuildContext context, app_chat.Chat chat) {
    showDialog(
      context: context,
      builder: (context) => _RenameChatDialog(
        chat: chat,
        chatBloc: this.context.read<ChatBloc>(),
      ),
    );
  }

  void _showExportDialog(BuildContext context, app_chat.Chat chat) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (context) =>
            ExportBloc(chatRepository: context.read<ChatBloc>().repository),
        child: ExportDialog(chatId: chat.id, chatTitle: chat.title),
      ),
    );
  }
}

class _ChatSettingsDialog extends StatefulWidget {
  final app_chat.Chat chat;
  final ChatBloc chatBloc;

  const _ChatSettingsDialog({required this.chat, required this.chatBloc});

  @override
  State<_ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<_ChatSettingsDialog> {
  late bool _useDeepThink;
  late bool _useWebSearch;
  late TextEditingController _systemPromptController;

  @override
  void initState() {
    super.initState();
    _useDeepThink = widget.chat.useDeepThink;
    _useWebSearch = widget.chat.useWebSearch;
    _systemPromptController = TextEditingController(
      text: widget.chat.systemPrompt ?? '',
    );
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A3A),
      title: const Text(
        'Настройки чата',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DeepThink toggle
            Row(
              children: [
                Switch(
                  value: _useDeepThink,
                  onChanged: (value) {
                    setState(() {
                      _useDeepThink = value;
                    });
                  },
                  activeColor: const Color(0xFF4F9CF9),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DeepThink',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Более глубокое рассуждение (медленнее, но точнее)',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // WebSearch toggle
            Row(
              children: [
                Switch(
                  value: _useWebSearch,
                  onChanged: (value) {
                    setState(() {
                      _useWebSearch = value;
                    });
                  },
                  activeColor: const Color(0xFF4F9CF9),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WebSearch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Поиск актуальной информации в интернете',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // System prompt
            const Text(
              'Системный промпт',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3A3A4A)),
              ),
              child: TextField(
                controller: _systemPromptController,
                style: const TextStyle(color: Colors.white),
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      'Введите системный промпт для настройки поведения ИИ...',
                  hintStyle: TextStyle(color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Отмена',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        TextButton(
          onPressed: () {
            // Сохраняем настройки
            widget.chatBloc.add(
              UpdateChatSettings(widget.chat.id, {
                'useDeepThink': _useDeepThink,
                'useWebSearch': _useWebSearch,
                'systemPrompt': _systemPromptController.text.trim().isEmpty
                    ? null
                    : _systemPromptController.text.trim(),
              }),
            );
            Navigator.of(context).pop();
          },
          child: const Text(
            'Сохранить',
            style: TextStyle(color: Color(0xFF4F9CF9)),
          ),
        ),
      ],
    );
  }
}

class _RenameChatDialog extends StatefulWidget {
  final app_chat.Chat chat;
  final ChatBloc chatBloc;

  const _RenameChatDialog({required this.chat, required this.chatBloc});

  @override
  State<_RenameChatDialog> createState() => _RenameChatDialogState();
}

class _RenameChatDialogState extends State<_RenameChatDialog> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chat.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A3A),
      title: const Text(
        'Переименовать чат',
        style: TextStyle(color: Colors.white),
      ),
      content: Container(
        width: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A3A4A)),
        ),
        child: TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите новое название чата...',
            hintStyle: TextStyle(color: Color(0xFF64748B)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(12),
          ),
          onSubmitted: (_) => _saveTitle(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Отмена',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        TextButton(
          onPressed: _saveTitle,
          child: const Text(
            'Сохранить',
            style: TextStyle(color: Color(0xFF4F9CF9)),
          ),
        ),
      ],
    );
  }

  void _saveTitle() {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.chat.title) {
      widget.chatBloc.add(RenameChat(widget.chat.id, newTitle));
    }
    Navigator.of(context).pop();
  }
}
