/// Удаляет HTML-теги и сжимает пробелы для отображения в Text.
String stripHtml(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  s = s.replaceAll(RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
  s = s.replaceAll(RegExp(r'&nbsp;'), ' ');
  s = s.replaceAll(RegExp(r'&amp;'), '&');
  s = s.replaceAll(RegExp(r'&lt;'), '<');
  s = s.replaceAll(RegExp(r'&gt;'), '>');
  s = s.replaceAll(RegExp(r'&quot;'), '"');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.trim();
}
