import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../chat/chat_bloc.dart';

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
        child: Center(
          child: Text(
            'UI для чата будет переписан заново.',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ), // Placeholder for the chat UI
      ),
    );
  }
}

// Removed ChatSidebar, ChatListItem, ChatArea, EmptyChatArea, _ExportOption classes
