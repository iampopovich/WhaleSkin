import 'export_format.dart';

class ExportResult {
  final String filePath;
  final ExportFormat format;
  final DateTime exportedAt;
  final int fileSize;

  const ExportResult({
    required this.filePath,
    required this.format,
    required this.exportedAt,
    required this.fileSize,
  });

  String get fileName => filePath.split('/').last;
}

class ExportOptions {
  final ExportFormat format;
  final bool includeTimestamps;
  final bool includeMetadata;
  final String? customTitle;

  const ExportOptions({
    required this.format,
    this.includeTimestamps = true,
    this.includeMetadata = true,
    this.customTitle,
  });

  ExportOptions copyWith({
    ExportFormat? format,
    bool? includeTimestamps,
    bool? includeMetadata,
    String? customTitle,
  }) {
    return ExportOptions(
      format: format ?? this.format,
      includeTimestamps: includeTimestamps ?? this.includeTimestamps,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      customTitle: customTitle ?? this.customTitle,
    );
  }
}
