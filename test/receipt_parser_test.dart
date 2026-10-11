import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/features/parser/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();

  test('parses labeled VND total with dots', () {
    const text = '''
CO.OPMART VINCOM
Tel: 1900 1234
Milk 2x
TOTAL: 150.000 đ
15/03/2026
''';
    final parsed = parser.parse(text);
    expect(parsed.merchant, contains('CO.OPMART'));
    expect(parsed.amountVnd, 150000);
    expect(parsed.date, DateTime(2026, 3, 15));
  });

  test('parses comma VND and thanh toan label', () {
    const text = '''
Big C Da Nang
Bread
TONG THANH TOAN 89,500 VND
01-10-2026
''';
    final parsed = parser.parse(text);
    expect(parsed.amountVnd, 89500);
    expect(parsed.date, DateTime(2026, 10, 1));
    expect(parsed.merchant?.toLowerCase(), contains('big c'));
  });

  test('falls back to largest lower money token', () {
    const text = '''
Mini Mart
Item A 12.000
Item B 8.000
45.000 đ
''';
    final parsed = parser.parse(text);
    expect(parsed.amountVnd, 45000);
  });

  test('returns nulls for empty noise', () {
    final parsed = parser.parse('hello world');
    expect(parsed.amountVnd, isNull);
    expect(parsed.date, isNull);
  });

  test('Hi4 Coffee receipt: ignores invoice So and reads Tong thanh toan', () {
    const text = '''
Hi4 Coffee & Workspace - 02 NVT
02 Nguyễn Văn Trỗi, Phường Hòa Cường, Đà Nẵng
Hotline: 0905720204
HÓA ĐƠN THANH TOÁN
Số: 2601055567
Số chờ: 6
Ngày: 11/10/2026 (07:39 CH - 07:39 CH)
Thu ngân: Ngô Huỳnh Như
Tên món SL ĐG % KM TT
Trà Đào Ô Long Cam Sả (M) 1 49.000  49.000
Tổng 49.000
Tiền hàng 49.000đ
Tổng thanh toán 49.000đ
Chuyển khoản 49.000đ
Pass wifi: 24242424
Trân trọng cảm ơn!
''';
    final parsed = parser.parse(text);
    expect(parsed.amountVnd, 49000);
    expect(parsed.amountVnd, isNot(2601055567));
    expect(parsed.date, DateTime(2026, 10, 11));
    expect(parsed.merchant?.toLowerCase(), contains('hi4'));
  });

  test('rejects bare invoice-like digit runs', () {
    const text = '''
Some Shop
HÓA ĐƠN THANH TOÁN
Số: 2601055567
Thanks
''';
    final parsed = parser.parse(text);
    expect(parsed.amountVnd, isNull);
  });
}
