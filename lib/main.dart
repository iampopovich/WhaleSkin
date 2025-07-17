import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme_manager.dart';
import 'core/theme_provider.dart';
import 'data/repositories/chat_repository.dart';
import 'features/chat/chat_bloc.dart';
import 'features/settings/api_key_screen.dart';
import 'features/chat/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final themeManager = ThemeManager();
  await themeManager.init();

  runApp(MyApp(themeManager: themeManager));
}

class MyApp extends StatelessWidget {
  final ThemeManager themeManager;

  const MyApp({super.key, required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      themeManager: themeManager,
      child: ListenableBuilder(
        listenable: themeManager,
        builder: (context, child) {
          return MaterialApp(
            title: 'WhaleSkin',
            theme: themeManager.currentTheme,
            home: BlocProvider(
              create: (context) => ChatBloc(ChatRepository())..add(LoadChats()),
              child: const AppRouter(),
            ),
            routes: {
              '/api-key': (context) => BlocProvider.value(
                value: context.read<ChatBloc>(),
                child: const ApiKeyScreen(),
              ),
              '/home': (context) => BlocProvider.value(
                value: context.read<ChatBloc>(),
                child: const HomeScreen(),
              ),
            },
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return const SizedBox.shrink(); // Заглушка вместо loading UI
        }

        if (state is ChatLoaded) {
          if (state.hasApiKey) {
            return const HomeScreen();
          } else {
            return const ApiKeyScreen();
          }
        }

        if (state is ChatError) {
          return const ApiKeyScreen();
        }

        return const ApiKeyScreen();
      },
    );
  }
}
