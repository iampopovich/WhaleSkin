import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onNewChat;
  final VoidCallback? onSettings;
  final VoidCallback? onSearch;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.onNewChat,
    this.onSettings,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Ctrl+N - новый чат
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const NewChatIntent(),
        // Ctrl+, - настройки
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma):
            const SettingsIntent(),
        // Ctrl+F - поиск
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const SearchIntent(),
        // Ctrl+/ - показать горячие клавиши
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.slash):
            const ShowShortcutsIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          NewChatIntent: CallbackAction<NewChatIntent>(
            onInvoke: (intent) => onNewChat?.call(),
          ),
          SettingsIntent: CallbackAction<SettingsIntent>(
            onInvoke: (intent) => onSettings?.call(),
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) => onSearch?.call(),
          ),
          ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(
            onInvoke: (intent) => _showShortcutsDialog(context),
          ),
        },
        child: child,
      ),
    );
  }

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Горячие клавиши',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2A2A3A),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ShortcutRow(keys: 'Ctrl + N', description: 'Создать новый чат'),
            _ShortcutRow(keys: 'Ctrl + ,', description: 'Открыть настройки'),
            _ShortcutRow(keys: 'Ctrl + F', description: 'Поиск по чатам'),
            _ShortcutRow(
              keys: 'Ctrl + /',
              description: 'Показать горячие клавиши',
            ),
          ],
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

class _ShortcutRow extends StatelessWidget {
  final String keys;
  final String description;

  const _ShortcutRow({required this.keys, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF3A3A4A)),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                color: Color(0xFF4F9CF9),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// Intent classes
class NewChatIntent extends Intent {
  const NewChatIntent();
}

class SettingsIntent extends Intent {
  const SettingsIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}
