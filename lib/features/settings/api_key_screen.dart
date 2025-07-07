import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../chat/chat_bloc.dart';

class ApiKeyScreen extends StatelessWidget {
  const ApiKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        // Бизнес-логика переходов и обработки состояний
        if (state is ChatLoaded && state.hasApiKey) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is ApiKeyTestSuccess) {
          context.read<ChatBloc>().add(SetApiKey(state.apiKey));
        }
        // Ошибки и прочее UI не обрабатываются
      },
      child: const SizedBox.shrink(), // Заглушка, UI будет переписан
    );
  }
}
