import 'package:flutter_test/flutter_test.dart';
import 'package:whaleskin/features/export/models/export_models.dart';
import 'package:whaleskin/features/export/models/export_format.dart';

void main() {
  group('ExportOptions', () {
    test('should create with default values', () {
      final options = ExportOptions(format: ExportFormat.json);

      expect(options.format, ExportFormat.json);
      expect(options.includeTimestamps, true);
      expect(options.includeMetadata, true);
      expect(options.customTitle, null);
    });

    test('should create with custom values', () {
      final options = ExportOptions(
        format: ExportFormat.pdf,
        includeTimestamps: false,
        includeMetadata: false,
        customTitle: 'Custom Title',
      );

      expect(options.format, ExportFormat.pdf);
      expect(options.includeTimestamps, false);
      expect(options.includeMetadata, false);
      expect(options.customTitle, 'Custom Title');
    });

    test('should copy with new values', () {
      final original = ExportOptions(format: ExportFormat.json);
      final copied = original.copyWith(
        format: ExportFormat.markdown,
        includeTimestamps: false,
      );

      expect(copied.format, ExportFormat.markdown);
      expect(copied.includeTimestamps, false);
      expect(copied.includeMetadata, true); // unchanged
      expect(copied.customTitle, null); // unchanged
    });
  });

  group('ExportResult', () {
    test('should create correctly', () {
      final now = DateTime.now();
      final result = ExportResult(
        filePath: '/path/to/file.json',
        format: ExportFormat.json,
        exportedAt: now,
        fileSize: 1024,
      );

      expect(result.filePath, '/path/to/file.json');
      expect(result.format, ExportFormat.json);
      expect(result.exportedAt, now);
      expect(result.fileSize, 1024);
    });

    test('should extract filename correctly', () {
      final result = ExportResult(
        filePath: '/long/path/to/my_file.pdf',
        format: ExportFormat.pdf,
        exportedAt: DateTime.now(),
        fileSize: 2048,
      );

      expect(result.fileName, 'my_file.pdf');
    });
  });
}
