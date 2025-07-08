import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/repositories/chat_repository.dart';
import 'features/chat/chat_bloc.dart';
import 'features/settings/api_key_screen.dart';
import 'features/chat/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhaleSkin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F9CF9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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
