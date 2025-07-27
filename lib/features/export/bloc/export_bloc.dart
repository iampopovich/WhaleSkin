import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/chat_repository.dart';
import '../services/export_service.dart';
import 'export_event.dart';
import 'export_state.dart';

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ChatRepository _chatRepository;

  ExportBloc({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(ExportInitial()) {
    on<ExportChatRequested>(_onExportChatRequested);
    on<ShareExportRequested>(_onShareExportRequested);
    on<PrintExportRequested>(_onPrintExportRequested);
    on<ClearExportHistory>(_onClearExportHistory);
  }

  Future<void> _onExportChatRequested(
    ExportChatRequested event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportInProgress(chatId: event.chatId, format: event.options.format));

    try {
      // Получаем данные чата
      final chat = _chatRepository.getChatById(event.chatId);
      if (chat == null) {
        emit(ExportError('Чат не найден'));
        return;
      }

      final messages = _chatRepository.getMessagesForChat(event.chatId);

      // Экспортируем чат
      final result = await ExportService.exportChat(
        chat,
        messages,
        event.options,
      );

      emit(ExportSuccess(result));
    } catch (e) {
      emit(ExportError('Ошибка экспорта: $e'));
    }
  }

  Future<void> _onShareExportRequested(
    ShareExportRequested event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportSharing(event.filePath));

    try {
      await ExportService.shareFile(event.filePath);
      emit(ExportInitial());
    } catch (e) {
      emit(ExportError('Ошибка при попытке поделиться файлом: $e'));
    }
  }

  Future<void> _onPrintExportRequested(
    PrintExportRequested event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportPrinting(event.filePath));

    try {
      await ExportService.printPdf(event.filePath);
      emit(ExportInitial());
    } catch (e) {
      emit(ExportError('Ошибка при печати: $e'));
    }
  }

  Future<void> _onClearExportHistory(
    ClearExportHistory event,
    Emitter<ExportState> emit,
  ) async {
    emit(ExportInitial());
  }
}
