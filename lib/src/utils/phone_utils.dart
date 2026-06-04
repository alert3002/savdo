/// Нормализация телефона Таджикистан (+992) барои API.
/// 9 рақам: 92…, 98…, 78…, 90… → +992XXXXXXXXX
String normalizeTajikPhoneForApi(String raw) {
  var s = raw.trim();
  if (s.startsWith('+')) {
    return s.replaceAll(RegExp(r'[^\d+]'), '');
  }

  final digits = s.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 9) {
    return '+992$digits';
  }
  if (digits.length == 12 && digits.startsWith('992')) {
    return '+$digits';
  }
  if (digits.length == 10 && digits.startsWith('0')) {
    return '+992${digits.substring(1)}';
  }
  if (digits.isNotEmpty) {
    return '+$digits';
  }
  return s;
}
