import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ExpenseDatabase {
  ExpenseDatabase._();
  static final ExpenseDatabase instance = ExpenseDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ocr_expenses.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            amount_vnd INTEGER NOT NULL,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            notes TEXT,
            thumbnail_path TEXT,
            image_path TEXT,
            ocr_raw_text TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
