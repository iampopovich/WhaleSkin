import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../chat/chat_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text('Настройки', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2A2A3A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Карточка с информацией о приложении
              Card(
                color: const Color(0xFF2A2A3A),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.chat,
                            color: Color(0xFF4F9CF9),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WhaleSkin',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'DeepSeek API Wrapper',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Версия 1.0.0',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Карточка настроек API
              Card(
                color: const Color(0xFF2A2A3A),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'API Настройки',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(
                          Icons.key,
                          color: Color(0xFF4F9CF9),
                        ),
                        title: const Text(
                          'Изменить API ключ',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          state is ChatLoaded && state.hasApiKey
                              ? 'API ключ настроен'
                              : 'API ключ не установлен',
                          style: TextStyle(
                            color: state is ChatLoaded && state.hasApiKey
                                ? Colors.green[400]
                                : Colors.red[400],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed('/api-key');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Карточка действий
              Card(
                color: const Color(0xFF2A2A3A),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Действия',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(
                          Icons.refresh,
                          color: Color(0xFF4F9CF9),
                        ),
                        title: const Text(
                          'Перезагрузить чаты',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Обновить список чатов',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        onTap: () {
                          context.read<ChatBloc>().add(LoadChats());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Чаты обновлены'),
                              backgroundColor: Color(0xFF4F9CF9),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Color(0xFF3A3A4A)),
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline,
                          color: Color(0xFF4F9CF9),
                        ),
                        title: const Text(
                          'О приложении',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Информация о WhaleSkin',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        onTap: () {
                          _showAboutDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3A),
        title: const Text(
          'О приложении',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'WhaleSkin - это удобная обертка для DeepSeek API, '
          'которая предоставляет современный интерфейс для общения с ИИ.\n\n'
          'Возможности:\n'
          '• Создание и управление чатами\n'
          '• Закрепление важных диалогов\n'
          '• Экспорт в различные форматы\n'
          '• Настройка параметров модели',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Закрыть',
              style: TextStyle(color: Color(0xFF4F9CF9)),
            ),
          ),
        ],
      ),
    );
  }
}
