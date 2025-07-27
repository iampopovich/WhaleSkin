import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../export.dart';
import '../../../data/repositories/chat_repository.dart';

/// Простая кнопка экспорта для быстрого доступа
class ExportButton extends StatelessWidget {
  final String chatId;
  final String chatTitle;
  final ExportFormat defaultFormat;

  const ExportButton({
    super.key,
    required this.chatId,
    required this.chatTitle,
    this.defaultFormat = ExportFormat.json,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.file_download),
      tooltip: 'Экспорт чата',
      onPressed: () => _showExportDialog(context),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (context) =>
            ExportBloc(chatRepository: context.read<ChatRepository>()),
        child: ExportDialog(chatId: chatId, chatTitle: chatTitle),
      ),
    );
  }
}

/// Быстрый экспорт без диалога
class QuickExportButton extends StatelessWidget {
  final String chatId;
  final String chatTitle;
  final ExportFormat format;

  const QuickExportButton({
    super.key,
    required this.chatId,
    required this.chatTitle,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ExportBloc(chatRepository: context.read<ChatRepository>()),
      child: BlocConsumer<ExportBloc, ExportState>(
        listener: (context, state) {
          if (state is ExportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Экспорт завершен: ${state.result.fileName}'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Поделиться',
                  onPressed: () {
                    context.read<ExportBloc>().add(
                      ShareExportRequested(state.result.filePath),
                    );
                  },
                ),
              ),
            );
          } else if (state is ExportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ExportInProgress;
          return IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_getFormatIcon(format)),
            tooltip: 'Экспорт в ${format.displayName}',
            onPressed: isLoading ? null : () => _startExport(context),
          );
        },
      ),
    );
  }

  void _startExport(BuildContext context) {
    final options = ExportOptions(format: format);
    context.read<ExportBloc>().add(
      ExportChatRequested(chatId: chatId, options: options),
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object;
      case ExportFormat.markdown:
        return Icons.description;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
    }
  }
}
