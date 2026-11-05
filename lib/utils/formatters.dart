import '../core/constants.dart';

/// «منذ ٥ د» بالأرقام العربية.
String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${arabicDigits(diff.inMinutes)} د';
  if (diff.inHours < 24) {
    return diff.inHours == 1 ? 'منذ ساعة' : 'منذ ${arabicDigits(diff.inHours)} ساعة';
  }
  return diff.inDays == 1 ? 'منذ يوم' : 'منذ ${arabicDigits(diff.inDays)} يوم';
}

String arabicDigits(int value) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value.toString().split('').map((c) {
    final n = int.tryParse(c);
    return n == null ? c : digits[n];
  }).join();
}

/// «٣ زجاجات» / «زجاجة واحدة».
String unitsLabel(int units) {
  if (units == 1) return 'زجاجة واحدة';
  if (units == 2) return 'زجاجتان';
  if (units <= 10) return '${arabicDigits(units)} زجاجات';
  return '${arabicDigits(units)} زجاجة';
}

/// يحول الرقم المحلي (0912345678 أو 912345678) إلى صيغة دولية +249912345678.
String normalizePhone(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  final code = kCountryCode.replaceFirst('+', '');
  if (digits.startsWith('00$code')) digits = digits.substring(2 + code.length);
  if (digits.startsWith(code)) digits = digits.substring(code.length);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '$kCountryCode$digits';
}

bool isValidLocalPhone(String input) {
  final local = normalizePhone(input).substring(kCountryCode.length);
  return RegExp(r'^\d{9}$').hasMatch(local);
}
