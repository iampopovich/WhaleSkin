import 'package:flutter_test/flutter_test.dart';
import 'package:whaleskin/features/export/models/export_format.dart';

void main() {
  group('ExportFormat', () {
    test('should have correct values', () {
      expect(ExportFormat.json.value, 'json');
      expect(ExportFormat.markdown.value, 'markdown');
      expect(ExportFormat.pdf.value, 'pdf');
    });

    test('should have correct display names', () {
      expect(ExportFormat.json.displayName, 'JSON');
      expect(ExportFormat.markdown.displayName, 'Markdown');
      expect(ExportFormat.pdf.displayName, 'PDF');
    });

    test('should parse from string correctly', () {
      expect(ExportFormat.fromString('json'), ExportFormat.json);
      expect(ExportFormat.fromString('markdown'), ExportFormat.markdown);
      expect(ExportFormat.fromString('pdf'), ExportFormat.pdf);
    });

    test('should return default format for unknown string', () {
      expect(ExportFormat.fromString('unknown'), ExportFormat.json);
      expect(ExportFormat.fromString(''), ExportFormat.json);
    });
  });
}
