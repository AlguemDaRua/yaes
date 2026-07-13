// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

void downloadTextFile(String filename, String content, String mimeType) {
  // BOM para o Excel abrir UTF-8 corretamente.
  final List<int> bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(content)];
  final html.Blob blob = html.Blob(<Object>[bytes], mimeType);
  final String url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
