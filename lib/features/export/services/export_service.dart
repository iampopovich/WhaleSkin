import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/message.dart';
import '../models/export_format.dart';
import '../models/export_models.dart';

class ExportService {
  static Future<ExportResult> exportChat(
    Chat chat,
    List<Message> messages,
    ExportOptions options,
  ) async {
    final startTime = DateTime.now();
    String filePath;

    switch (options.format) {
      case ExportFormat.json:
        filePath = await _exportToJson(chat, messages, options);
        break;
      case ExportFormat.markdown:
        filePath = await _exportToMarkdown(chat, messages, options);
        break;
      case ExportFormat.pdf:
        filePath = await _exportToPdf(chat, messages, options);
        break;
    }

    final file = File(filePath);
    final fileSize = await file.length();

    return ExportResult(
      filePath: filePath,
      format: options.format,
      exportedAt: startTime,
      fileSize: fileSize,
    );
  }

  static Future<String> _exportToJson(
    Chat chat,
    List<Message> messages,
    ExportOptions options,
  ) async {
    final data = <String, dynamic>{
      'chat': chat.toJson(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };

    if (options.includeMetadata) {
      data['exportedAt'] = DateTime.now().toIso8601String();
      data['exportOptions'] = {
        'format': options.format.value,
        'includeTimestamps': options.includeTimestamps,
        'includeMetadata': options.includeMetadata,
        'customTitle': options.customTitle,
      };
    }

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName(
      chat,
      options.format,
      options.customTitle,
    );
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonString);

    return file.path;
  }

  static Future<String> _exportToMarkdown(
    Chat chat,
    List<Message> messages,
    ExportOptions options,
  ) async {
    final buffer = StringBuffer();
    final title = options.customTitle ?? chat.title;

    buffer.writeln('# $title');
    buffer.writeln('');

    if (options.includeMetadata) {
      buffer.writeln('**Создан:** ${_formatDateTime(chat.createdAt)}');
      buffer.writeln('**Экспортирован:** ${_formatDateTime(DateTime.now())}');
      buffer.writeln('');
    }

    for (final message in messages) {
      buffer.writeln(
        '## ${message.role == 'user' ? 'Пользователь' : 'Ассистент'}',
      );
      buffer.writeln('');
      buffer.writeln(message.content);
      buffer.writeln('');

      if (options.includeTimestamps) {
        buffer.writeln('*${_formatDateTime(message.timestamp)}*');
        buffer.writeln('');
      }

      buffer.writeln('---');
      buffer.writeln('');
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName(
      chat,
      options.format,
      options.customTitle,
    );
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  static Future<String> _exportToPdf(
    Chat chat,
    List<Message> messages,
    ExportOptions options,
  ) async {
    final pdf = pw.Document();
    final title = options.customTitle ?? chat.title;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final widgets = <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];

          if (options.includeMetadata) {
            widgets.addAll([
              pw.Paragraph(
                text: 'Создан: ${_formatDateTime(chat.createdAt)}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
              pw.Paragraph(
                text: 'Экспортирован: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 20),
            ]);
          }

          widgets.addAll(
            messages.map((message) => _buildMessageWidget(message, options)),
          );

          return widgets;
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName(
      chat,
      options.format,
      options.customTitle,
    );
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static pw.Widget _buildMessageWidget(Message message, ExportOptions options) {
    final isUser = message.role == 'user';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: isUser ? PdfColors.blue100 : PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isUser ? 'Пользователь' : 'Ассистент',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: isUser ? PdfColors.blue800 : PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  message.content,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (options.includeTimestamps) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _formatDateTime(message.timestamp),
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _generateFileName(
    Chat chat,
    ExportFormat format,
    String? customTitle,
  ) {
    final title = customTitle ?? chat.title;
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'chat_${sanitizedTitle}_$timestamp.${format.value}';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Открывает диалог для печати PDF
  static Future<void> printPdf(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }

  /// Делится файлом через системный диалог
  static Future<void> shareFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: file.path.split('/').last,
      );
    }
  }
}
