import '../models/expense.dart';
import '../models/expense_category.dart';
import 'expense_database.dart';
import 'receipt_storage.dart';

class ExpenseRepository {
  ExpenseRepository({
    ExpenseDatabase? database,
    ReceiptStorage? storage,
  })  : _database = database ?? ExpenseDatabase.instance,
        _storage = storage ?? ReceiptStorage();

  final ExpenseDatabase _database;
  final ReceiptStorage _storage;

  Future<List<Expense>> getAll() async {
    final db = await _database.database;
    final rows = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> getById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<int> insert(Expense expense) async {
    final db = await _database.database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<int> update(Expense expense) async {
    final db = await _database.database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> delete(Expense expense) async {
    final db = await _database.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expense.id]);
    await _storage.deleteIfExists(expense.thumbnailPath);
    await _storage.deleteIfExists(expense.imagePath);
  }

  Future<int> monthTotal(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final items = await getAll();
    return items
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .fold<int>(0, (sum, e) => sum + e.amountVnd);
  }

  Future<Map<ExpenseCategory, int>> totalsByCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    final items = await getAll();
    final map = {for (final c in ExpenseCategory.values) c: 0};
    for (final e in items) {
      if (from != null && e.date.isBefore(from)) continue;
      if (to != null && !e.date.isBefore(to)) continue;
      map[e.category] = map[e.category]! + e.amountVnd;
    }
    return map;
  }

  /// Monday–Sunday totals for the week containing [anchor].
  Future<List<int>> weeklyTotals(DateTime anchor) async {
    final monday = _mondayOf(anchor);
    final items = await getAll();
    final totals = List<int>.filled(7, 0);
    for (final e in items) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      final diff = day.difference(monday).inDays;
      if (diff >= 0 && diff < 7) {
        totals[diff] += e.amountVnd;
      }
    }
    return totals;
  }

  DateTime _mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  ReceiptStorage get storage => _storage;
}
