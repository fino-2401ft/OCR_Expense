import 'expense_category.dart';

class Expense {
  final int? id;
  final String merchant;
  final int amountVnd;
  final DateTime date;
  final ExpenseCategory category;
  final String? notes;
  final String? thumbnailPath;
  final String? imagePath;
  final String? ocrRawText;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.merchant,
    required this.amountVnd,
    required this.date,
    required this.category,
    this.notes,
    this.thumbnailPath,
    this.imagePath,
    this.ocrRawText,
    required this.createdAt,
  });

  Expense copyWith({
    int? id,
    String? merchant,
    int? amountVnd,
    DateTime? date,
    ExpenseCategory? category,
    String? notes,
    String? thumbnailPath,
    String? imagePath,
    String? ocrRawText,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amountVnd: amountVnd ?? this.amountVnd,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      imagePath: imagePath ?? this.imagePath,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount_vnd': amountVnd,
      'date': date.toIso8601String(),
      'category': category.storageValue,
      'notes': notes,
      'thumbnail_path': thumbnailPath,
      'image_path': imagePath,
      'ocr_raw_text': ocrRawText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amountVnd: map['amount_vnd'] as int,
      date: DateTime.parse(map['date'] as String),
      category: ExpenseCategory.fromStorage(map['category'] as String),
      notes: map['notes'] as String?,
      thumbnailPath: map['thumbnail_path'] as String?,
      imagePath: map['image_path'] as String?,
      ocrRawText: map['ocr_raw_text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
