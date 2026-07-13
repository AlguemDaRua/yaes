import 'csv_export_stub.dart' if (dart.library.html) 'csv_export_web.dart'
    as platform;

/// Gera um CSV a partir de [rows] (a primeira linha deve ser o cabeçalho)
/// e descarrega-o no browser como [filename].
void downloadCsv(String filename, List<List<Object?>> rows) {
  final StringBuffer buffer = StringBuffer();
  for (final List<Object?> row in rows) {
    buffer.writeln(row.map(_escape).join(','));
  }
  platform.downloadTextFile(filename, buffer.toString(), 'text/csv');
}

String _escape(Object? value) {
  final String text = value == null ? '' : value.toString();
  if (text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}
