import '../models/export_models.dart';
import '../models/export_format.dart';

abstract class ExportState {}

class ExportInitial extends ExportState {}

class ExportInProgress extends ExportState {
  final String chatId;
  final ExportFormat format;

  ExportInProgress({required this.chatId, required this.format});
}

class ExportSuccess extends ExportState {
  final ExportResult result;

  ExportSuccess(this.result);
}

class ExportError extends ExportState {
  final String message;

  ExportError(this.message);
}

class ExportSharing extends ExportState {
  final String filePath;

  ExportSharing(this.filePath);
}

class ExportPrinting extends ExportState {
  final String filePath;

  ExportPrinting(this.filePath);
}
