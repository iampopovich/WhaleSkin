import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ExportService {
  static Future<String> exportChatToJson(
    Chat chat,
    List<Message> messages,
  ) async {
    final data = {
      'chat': chat.toJson(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/chat_${chat.id}_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonString);

    return file.path;
  }

  static Future<String> exportChatToMarkdown(
    Chat chat,
    List<Message> messages,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('# ${chat.title}');
    buffer.writeln('');
    buffer.writeln('**Создан:** ${_formatDateTime(chat.createdAt)}');
    buffer.writeln('**Экспортирован:** ${_formatDateTime(DateTime.now())}');
    buffer.writeln('');

    for (final message in messages) {
      buffer.writeln(
        '## ${message.role == 'user' ? 'Пользователь' : 'Ассистент'}',
      );
      buffer.writeln('');
      buffer.writeln(message.content);
      buffer.writeln('');
      buffer.writeln('*${_formatDateTime(message.timestamp)}*');
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/chat_${chat.id}_${DateTime.now().millisecondsSinceEpoch}.md',
    );
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  static Future<String> exportChatToPdf(
    Chat chat,
    List<Message> messages,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                chat.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text: 'Создан: ${_formatDateTime(chat.createdAt)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
            pw.Paragraph(
              text: 'Экспортирован: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 20),
            ...messages.map((message) => _buildMessageWidget(message)),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/chat_${chat.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static pw.Widget _buildMessageWidget(Message message) {
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
                pw.SizedBox(height: 8),
                pw.Text(
                  _formatDateTime(message.timestamp),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
