import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ApiKeysDb {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'settings.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE api_keys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          gemini_api_key TEXT,
          groq_api_key TEXT
        )
        ''');
      },
    );
  }

  static Future<(String?, String?)> loadApiKeys() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'api_keys',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isNotEmpty) {
      return (result.first['gemini_api_key'] as String?, result.first['groq_api_key'] as String?);
    } else {
      return (null, null);
    }
  }

  static Future<void> saveKeys(String geminiApiKey, String groqApiKey) async {
    final db = await database;
    await db.delete('api_keys', where: 'id = ?', whereArgs: [1]);
    await db.insert('api_keys', {
      'id': 1,
      'gemini_api_key': geminiApiKey,
      'groq_api_key': groqApiKey,
    });
  }
}