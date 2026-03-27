import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'filter_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table for storing BLE logs
    await db.execute('''
      CREATE TABLE ble_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT,
        isResponse INTEGER,
        timestamp TEXT
      )
    ''');
    
    // You can add more tables here for filters or other data
  }

  Future<int> insertLog(String text, bool isResponse) async {
    final db = await database;
    final id = await db.insert('ble_logs', {
      'text': text,
      'isResponse': isResponse ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Clean up old logs whenever a new one is inserted
    await deleteOldLogs();
    
    return id;
  }

  Future<List<Map<String, dynamic>>> getLogs() async {
    final db = await database;
    return await db.query('ble_logs', orderBy: 'timestamp DESC');
  }

  Future<void> deleteOldLogs() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    
    await db.delete(
      'ble_logs',
      where: 'timestamp < ?',
      whereArgs: [sevenDaysAgo],
    );
  }

  Future<void> clearAllLogs() async {
    final db = await database;
    await db.delete('ble_logs');
  }
}
