import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../chat/chat_bloc.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatExported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Чат экспортирован в ${state.format.toUpperCase()}',
                ),
                backgroundColor: const Color(0xFF4F9CF9),
                action: SnackBarAction(
                  label: 'Открыть',
                  textColor: Colors.white,
                  onPressed: () {
                    // TODO: Open file
                  },
                ),
              ),
            );
          }
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4F9CF9)),
              );
            }

            if (state is ChatError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ChatBloc>().add(LoadChats());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F9CF9),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is ChatLoaded) {
              return Row(
                children: [
                  // Sidebar with chat list
                  Container(
                    width: 320,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A3A),
                      border: Border(
                        right: BorderSide(color: Color(0xFF404040), width: 1),
                      ),
                    ),
                    child: ChatSidebar(
                      chats: state.chats,
                      selectedChat: state.selectedChat,
                    ),
                  ),

                  // Main chat area
                  Expanded(
                    child: state.selectedChat != null
                        ? ChatArea(
                            chat: state.selectedChat!,
                            messages: state.messages,
                            isLoading: state is MessageSending,
                            isExporting: state is ChatExporting,
                          )
                        : const EmptyChatArea(),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class ChatSidebar extends StatelessWidget {
  final List<Chat> chats;
  final Chat? selectedChat;

  const ChatSidebar({super.key, required this.chats, this.selectedChat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with new chat button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Чаты',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<ChatBloc>(),
                        child: const SettingsScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Color(0xFF64748B)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3A4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  context.read<ChatBloc>().add(CreateChat());
                },
                icon: const Icon(Icons.add, color: Color(0xFF4F9CF9)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3A4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chat list
        Expanded(
          child: chats.isEmpty
              ? const Center(
                  child: Text(
                    'Нет чатов\nНажмите + чтобы создать новый',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final isSelected = selectedChat?.id == chat.id;

                    return ChatListItem(
                      chat: chat,
                      isSelected: isSelected,
                      onTap: () {
                        context.read<ChatBloc>().add(SelectChat(chat.id));
                      },
                      onPin: () {
                        context.read<ChatBloc>().add(ToggleChatPin(chat.id));
                      },
                      onDelete: () {
                        _showDeleteDialog(context, chat);
                      },
                      onRename: () {
                        _showRenameDialog(context, chat);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3A),
          title: const Text(
            'Удалить чат?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Чат "${chat.title}" будет удален навсегда.',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ChatBloc>().add(DeleteChat(chat.id));
              },
              child: Text(
                'Удалить',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, Chat chat) {
    final controller = TextEditingController(text: chat.title);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3A),
          title: const Text(
            'Переименовать чат',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Введите новое название',
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF1E1E2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4F9CF9)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop();
                context.read<ChatBloc>().add(RenameChat(chat.id, value.trim()));
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            TextButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  Navigator.of(context).pop();
                  context.read<ChatBloc>().add(RenameChat(chat.id, newTitle));
                }
              },
              child: const Text(
                'Сохранить',
                style: TextStyle(color: Color(0xFF4F9CF9)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChatListItem extends StatelessWidget {
  final Chat chat;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.isSelected,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4F9CF9).withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: const Color(0xFF4F9CF9), width: 1)
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: chat.isPinned
            ? const Icon(Icons.push_pin, color: Color(0xFF4F9CF9), size: 16)
            : null,
        title: Text(
          chat.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(chat.lastMessageAt),
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 18),
          color: const Color(0xFF3A3A4A),
          onSelected: (value) {
            switch (value) {
              case 'pin':
                onPin();
                break;
              case 'rename':
                onRename();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'pin',
              child: Row(
                children: [
                  Icon(
                    chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: const Color(0xFF4F9CF9),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    chat.isPinned ? 'Открепить' : 'Закрепить',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'rename',
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF4F9CF9), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Переименовать',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text('Удалить', style: TextStyle(color: Colors.red.shade400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

class ChatArea extends StatefulWidget {
  final Chat chat;
  final List<Message> messages;
  final bool isLoading;
  final bool isExporting;

  const ChatArea({
    super.key,
    required this.chat,
    required this.messages,
    required this.isLoading,
    this.isExporting = false,
  });

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A3A),
            border: Border(
              bottom: BorderSide(color: Color(0xFF404040), width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                widget.chat.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  _showChatSettingsDialog(context, widget.chat);
                },
                icon: const Icon(Icons.tune, color: Color(0xFF64748B)),
                tooltip: 'Настройки чата',
              ),
              IconButton(
                onPressed: widget.isExporting
                    ? null
                    : () {
                        _showExportDialog(context, widget.chat.id);
                      },
                icon: widget.isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : const Icon(Icons.download, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),

        // Messages area
        Expanded(
          child: widget.messages.isEmpty
              ? const Center(
                  child: Text(
                    'Начните разговор',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.messages[index];
                    return MessageBubble(message: message);
                  },
                ),
        ),

        // Loading indicator
        if (widget.isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F9CF9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF4F9CF9),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Печатает...',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A3A),
            border: Border(top: BorderSide(color: Color(0xFF404040), width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Напишите сообщение...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF3A3A4A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.isLoading ? null : _sendMessage,
                icon: Icon(
                  Icons.send,
                  color: widget.isLoading
                      ? const Color(0xFF64748B)
                      : const Color(0xFF4F9CF9),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF3A3A4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      context.read<ChatBloc>().add(SendMessage(text));
      _controller.clear();
    }
  }

  void _showExportDialog(BuildContext context, String chatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3A),
          title: const Text(
            'Экспорт чата',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Выберите формат для экспорта:',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              _ExportOption(
                icon: Icons.code,
                title: 'JSON',
                description: 'Структурированные данные',
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<ChatBloc>().add(ExportChat(chatId, 'json'));
                },
              ),
              const SizedBox(height: 8),
              _ExportOption(
                icon: Icons.text_snippet,
                title: 'Markdown',
                description: 'Текстовый формат',
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<ChatBloc>().add(ExportChat(chatId, 'markdown'));
                },
              ),
              const SizedBox(height: 8),
              _ExportOption(
                icon: Icons.picture_as_pdf,
                title: 'PDF',
                description: 'Готовый для печати документ',
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<ChatBloc>().add(ExportChat(chatId, 'pdf'));
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showChatSettingsDialog(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is! ChatLoaded) return const SizedBox();

              final currentChat = state.chats.firstWhere(
                (c) => c.id == chat.id,
                orElse: () => chat,
              );

              return AlertDialog(
                backgroundColor: const Color(0xFF2A2A3A),
                title: const Text(
                  'Настройки чата',
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentChat.systemPrompt != null &&
                        currentChat.systemPrompt!.isNotEmpty) ...[
                      Text(
                        'Системный промпт активен',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          currentChat.systemPrompt!.length > 100
                              ? '${currentChat.systemPrompt!.substring(0, 100)}...'
                              : currentChat.systemPrompt!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SwitchListTile(
                      title: const Text(
                        'DeepThink режим',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Использовать reasoning модель (deepseek-reasoner)',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      value: currentChat.useDeepThink,
                      activeColor: const Color(0xFF4F9CF9),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool value) {
                        context.read<ChatBloc>().add(
                          UpdateChatSettings(currentChat.id, {
                            'useDeepThink': value,
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text(
                        'Поиск в интернете',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'Включить поиск релевантной информации в сети',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      value: currentChat.useWebSearch,
                      activeColor: const Color(0xFF4F9CF9),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool value) {
                        context.read<ChatBloc>().add(
                          UpdateChatSettings(currentChat.id, {
                            'useWebSearch': value,
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showAdvancedSettingsDialog(context, currentChat);
                      },
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Расширенные настройки'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3A3A4A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Готово',
                      style: TextStyle(color: Color(0xFF4F9CF9)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAdvancedSettingsDialog(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is! ChatLoaded) return const SizedBox();

              final currentChat = state.chats.firstWhere(
                (c) => c.id == chat.id,
                orElse: () => chat,
              );

              final systemPromptController = TextEditingController(
                text: currentChat.systemPrompt ?? '',
              );
              final temperatureController = TextEditingController(
                text: currentChat.temperature.toString(),
              );
              final maxTokensController = TextEditingController(
                text: currentChat.maxTokens.toString(),
              );

              return AlertDialog(
                backgroundColor: const Color(0xFF2A2A3A),
                title: const Text(
                  'Расширенные настройки чата',
                  style: TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Системный промпт',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: systemPromptController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Опишите роль и поведение ИИ для этого чата...',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFF1E1E2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF4F9CF9),
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Temperature',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: temperatureController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '1.0',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E2E),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Max Tokens',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: maxTokensController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '2048',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E2E),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final updates = <String, dynamic>{};

                      if (systemPromptController.text != chat.systemPrompt) {
                        updates['systemPrompt'] =
                            systemPromptController.text.isEmpty
                            ? null
                            : systemPromptController.text;
                      }

                      final newTemperature = double.tryParse(
                        temperatureController.text,
                      );
                      if (newTemperature != null &&
                          newTemperature != chat.temperature) {
                        updates['temperature'] = newTemperature;
                      }

                      final newMaxTokens = int.tryParse(
                        maxTokensController.text,
                      );
                      if (newMaxTokens != null &&
                          newMaxTokens != chat.maxTokens) {
                        updates['maxTokens'] = newMaxTokens;
                      }

                      if (updates.isNotEmpty) {
                        context.read<ChatBloc>().add(
                          UpdateChatSettings(chat.id, updates),
                        );
                      }

                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F9CF9),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Сохранить'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF4F9CF9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF4F9CF9)
                        : const Color(0xFF3A3A4A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class EmptyChatArea extends StatelessWidget {
  const EmptyChatArea({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFF64748B)),
          SizedBox(height: 16),
          Text(
            'Выберите чат для начала',
            style: TextStyle(fontSize: 18, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF404040)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4F9CF9), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF64748B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
