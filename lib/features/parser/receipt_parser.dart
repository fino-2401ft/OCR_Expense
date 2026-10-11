import 'parsed_receipt.dart';

/// Heuristic regex parser for Vietnamese supermarket-style receipts.
class ReceiptParser {
  /// Strong total labels — prefer these over title noise like "HÓA ĐƠN THANH TOÁN".
  static final _strongTotalLabel = RegExp(
    r'(?:'
    r'tổng\s*thanh\s*toán|tong\s*thanh\s*toan|'
    r'grand\s*total|amount\s*due|total\s*due|'
    r'total\s*amount|final\s*total|'
    r'tiền\s*phải\s*trả|tien\s*phai\s*tra'
    r')'
    r'[^\d]{0,20}'
    r'([\d.,]+)\s*(vnd|vnđ|đ|d)?',
    caseSensitive: false,
  );

  static final _softTotalLabel = RegExp(
    r'(?:'
    r'tiền\s*hàng|tien\s*hang|'
    r'\btotal\b|\bsum\b|'
    r'\btổng\b|\btong\b'
    r')'
    r'(?!\s*thanh)'
    r'[^\d]{0,20}'
    r'([\d.,]+)\s*(vnd|vnđ|đ|d)?',
    caseSensitive: false,
  );

  static final _moneyWithCurrency = RegExp(
    r'([\d]{1,3}(?:[.,]\d{3})+|\d{1,7})\s*(?:vnd|vnđ|đ)\b',
    caseSensitive: false,
  );

  static final _formattedMoney = RegExp(
    r'\b([\d]{1,3}(?:[.,]\d{3})+)\b',
  );

  static final _date = RegExp(
    r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})\b',
  );

  static final _merchantNoise = RegExp(
    r'^(tel|phone|hotline|mst|tax|invoice|hóa đơn|hoa don|bill|receipt|'
    r'date|ngày|ngay|time|giờ|gio|số|so|#|\d+$)',
    caseSensitive: false,
  );

  ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return ParsedReceipt(
      merchant: _extractMerchant(lines),
      amountVnd: _extractAmount(rawText, lines),
      date: _extractDate(rawText),
      rawText: rawText,
    );
  }

  String? _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    for (final line in lines.take(6)) {
      if (line.length < 3) continue;
      if (_merchantNoise.hasMatch(line)) continue;
      if (_date.hasMatch(line)) continue;
      if (_looksLikeMoney(line)) continue;
      return line;
    }
    return lines.first;
  }

  int? _extractAmount(String rawText, List<String> lines) {
    // 1) Prefer explicit "Tổng thanh toán" / grand total style labels.
    final strong = _collectLabeled(rawText, _strongTotalLabel);
    if (strong.isNotEmpty) return _bestAmount(strong);

    // 2) Soft labels like "Tiền hàng" / "Total", money-like tokens only.
    final soft = _collectLabeled(rawText, _softTotalLabel);
    if (soft.isNotEmpty) return _bestAmount(soft);

    // 3) Tokens with currency suffix (đ / VND), prefer lower half.
    final withCurrency = _moneyWithCurrency.allMatches(rawText).toList();
    final currencyValues = <_ScoredAmount>[];
    for (final m in withCurrency) {
      final v = _toMoneyAmount(m.group(1)!);
      if (v != null) {
        currencyValues.add(_ScoredAmount(v, m.start));
      }
    }
    if (currencyValues.isNotEmpty) {
      return _preferLowerHalf(currencyValues, rawText.length);
    }

    // 4) Fallback: formatted money in bottom third (49.000 not 2601055567).
    final start = (lines.length * 2 / 3).floor();
    final bottom = lines.skip(start).join('\n');
    final bare = _formattedMoney
        .allMatches(bottom.isEmpty ? rawText : bottom)
        .map((m) => _toMoneyAmount(m.group(1)!))
        .whereType<int>()
        .where((v) => v >= 1000)
        .toList();
    if (bare.isEmpty) return null;
    return bare.reduce((a, b) => a > b ? a : b);
  }

  List<int> _collectLabeled(String rawText, RegExp pattern) {
    final values = <int>[];
    for (final m in pattern.allMatches(rawText)) {
      final token = m.group(1)!;
      final windowStart = (m.start - 16).clamp(0, rawText.length);
      final prefix = rawText.substring(windowStart, m.start).toLowerCase();
      // Skip invoice / order number prefixes: "Số: 2601055567"
      if (RegExp(r'(số|so|no\.?|invoice|mã|bill)\s*[:.#]?\s*$').hasMatch(prefix)) {
        continue;
      }
      // Skip title context: "HÓA ĐƠN THANH TOÁN" then next digits.
      if (RegExp(r'hóa\s*đơn|hoa\s*don').hasMatch(prefix) &&
          !RegExp(r'tổng|tong|tiền|tien|total').hasMatch(m.group(0)!.toLowerCase())) {
        continue;
      }
      final v = _toMoneyAmount(token);
      if (v != null) values.add(v);
    }
    return values;
  }

  int _bestAmount(List<int> values) {
    final plausible = values.where(_isPlausibleReceiptTotal).toList();
    final pool = plausible.isNotEmpty ? plausible : values;
    return pool.reduce((a, b) => a > b ? a : b);
  }

  int _preferLowerHalf(List<_ScoredAmount> values, int textLength) {
    final mid = textLength ~/ 2;
    final lower = values.where((v) => v.offset >= mid).toList();
    final pool = lower.isNotEmpty ? lower : values;
    return pool.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  DateTime? _extractDate(String rawText) {
    final labeled = RegExp(
      r'(?:ngày|ngay|date)\s*:?\s*(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})',
      caseSensitive: false,
    ).firstMatch(rawText);
    final match = labeled ?? _date.firstMatch(rawText);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    var year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeMoney(String line) {
    return _moneyWithCurrency.hasMatch(line) || _formattedMoney.hasMatch(line);
  }

  /// Converts a numeric token to VND.
  /// Rejects invoice-like IDs such as 2601055567 (no thousand separators).
  int? _toMoneyAmount(String token) {
    final cleaned = token.trim();
    if (cleaned.isEmpty) return null;

    final hasSeparator = cleaned.contains('.') || cleaned.contains(',');
    final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return null;

    // Hard reject bare long IDs (invoice / order numbers).
    if (!hasSeparator && digitsOnly.length >= 8) return null;

    if (hasSeparator) {
      final parts = cleaned.split(RegExp(r'[.,]'));
      // VND grouping uses 3-digit groups: 49.000 / 1.250.000
      if (parts.length >= 2 && parts.last.length != 3) {
        return null;
      }
      for (var i = 1; i < parts.length; i++) {
        if (parts[i].length != 3) return null;
      }
    }

    final value = int.tryParse(digitsOnly);
    if (value == null || value <= 0) return null;
    if (!_isPlausibleReceiptTotal(value)) return null;
    return value;
  }

  bool _isPlausibleReceiptTotal(int value) {
    return value >= 1000 && value <= 50000000;
  }
}

class _ScoredAmount {
  _ScoredAmount(this.value, this.offset);
  final int value;
  final int offset;
}
