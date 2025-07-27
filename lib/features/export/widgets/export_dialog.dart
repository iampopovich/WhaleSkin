import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/export_bloc.dart';
import '../bloc/export_event.dart';
import '../bloc/export_state.dart';
import '../models/export_format.dart';
import '../models/export_models.dart';

class ExportDialog extends StatefulWidget {
  final String chatId;
  final String chatTitle;

  const ExportDialog({
    super.key,
    required this.chatId,
    required this.chatTitle,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.json;
  bool _includeTimestamps = true;
  bool _includeMetadata = true;
  String? _customTitle;
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.chatTitle;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is ExportSuccess) {
          Navigator.of(context).pop();
          _showSuccessDialog(context, state.result);
        } else if (state is ExportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Экспорт чата'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название файла
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название файла',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _customTitle = value.isEmpty ? null : value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Формат экспорта
              const Text(
                'Формат экспорта:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: ExportFormat.values.map((format) {
                  return RadioListTile<ExportFormat>(
                    title: Text(format.displayName),
                    subtitle: Text(format.description),
                    value: format,
                    groupValue: _selectedFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedFormat = value!;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Опции экспорта
              const Text(
                'Опции:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              CheckboxListTile(
                title: const Text('Включать временные метки'),
                value: _includeTimestamps,
                onChanged: (value) {
                  setState(() {
                    _includeTimestamps = value ?? true;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Включать метаданные'),
                value: _includeMetadata,
                onChanged: (value) {
                  setState(() {
                    _includeMetadata = value ?? true;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          BlocBuilder<ExportBloc, ExportState>(
            builder: (context, state) {
              final isLoading = state is ExportInProgress;
              return ElevatedButton(
                onPressed: isLoading ? null : _startExport,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Экспортировать'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _startExport() {
    final options = ExportOptions(
      format: _selectedFormat,
      includeTimestamps: _includeTimestamps,
      includeMetadata: _includeMetadata,
      customTitle: _customTitle,
    );

    context.read<ExportBloc>().add(
      ExportChatRequested(chatId: widget.chatId, options: options),
    );
  }

  void _showSuccessDialog(BuildContext context, ExportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт завершен'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Файл сохранен: ${result.fileName}'),
            const SizedBox(height: 8),
            Text('Размер: ${_formatFileSize(result.fileSize)}'),
            Text('Формат: ${result.format.displayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ExportBloc>().add(
                ShareExportRequested(result.filePath),
              );
            },
            child: const Text('Поделиться'),
          ),
          if (result.format == ExportFormat.pdf)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ExportBloc>().add(
                  PrintExportRequested(result.filePath),
                );
              },
              child: const Text('Печать'),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}
