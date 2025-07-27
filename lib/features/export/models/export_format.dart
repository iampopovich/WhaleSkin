enum ExportFormat {
  json('json', 'JSON', 'Экспорт в формате JSON'),
  markdown('markdown', 'Markdown', 'Экспорт в формате Markdown'),
  pdf('pdf', 'PDF', 'Экспорт в формате PDF');

  const ExportFormat(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static ExportFormat fromString(String value) {
    return ExportFormat.values.firstWhere(
      (format) => format.value == value,
      orElse: () => ExportFormat.json,
    );
  }
}
