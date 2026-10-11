import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/main.dart';

void main() {
  testWidgets('app boots to Home tab', (tester) async {
    await tester.pumpWidget(const OcrExpenseApp());
    await tester.pump();
    // Allow Home FutureBuilder first frame without waiting forever.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Scan'), findsWidgets);
    expect(find.text('Analytics'), findsWidgets);
  });
}
