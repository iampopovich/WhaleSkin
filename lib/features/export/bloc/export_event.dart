import '../models/export_models.dart';

abstract class ExportEvent {}

class ExportChatRequested extends ExportEvent {
  final String chatId;
  final ExportOptions options;

  ExportChatRequested({required this.chatId, required this.options});
}

class ShareExportRequested extends ExportEvent {
  final String filePath;

  ShareExportRequested(this.filePath);
}

class PrintExportRequested extends ExportEvent {
  final String filePath;

  PrintExportRequested(this.filePath);
}

class ClearExportHistory extends ExportEvent {}
