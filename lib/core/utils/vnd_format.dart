import 'package:intl/intl.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');

String formatVnd(int amount) {
  return '${_vnd.format(amount).replaceAll(',', '.')} đ';
}

int? parseVndInput(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (cleaned.isEmpty) return null;
  return int.tryParse(cleaned);
}
