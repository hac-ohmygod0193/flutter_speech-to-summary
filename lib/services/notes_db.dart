import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/note.dart';
import 'dart:async';

class NotesDb {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'notes_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          file_name TEXT,
          result TEXT,
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        ) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ''');
      },
    );
  }
  static final _notesStreamController = StreamController<List<Note>>.broadcast();

  static Stream<List<Note>> get notesStream => _notesStreamController.stream;

  static Future<void> refreshNotes() async {
    final notes = await getNotes();
    _notesStreamController.add(notes);
  }
  static Future<void> createNote(String title, String fileName, Map<String, dynamic> result) async {
    final db = await database;
    await db.insert('notes', {
      'title': utf8.encode(title),
      'file_name': utf8.encode(fileName),
      'result': utf8.encode(jsonEncode(result)),
      'timestamp': DateTime.now().toString(),
    });
    await refreshNotes();
}

  static Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) {
      final resultMap = jsonDecode(utf8.decode(maps[i]['result']));
      return Note.fromMap({
        ...maps[i],
        'title': utf8.decode(maps[i]['title']),
        'file_name': utf8.decode(maps[i]['file_name']),
        'result': resultMap,
      });
    });
  }

  static Future<Note?> getNoteContent(int noteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
    if (maps.isNotEmpty) {
      final resultMap = jsonDecode(utf8.decode(maps.first['result']));
      return Note.fromMap({
        ...maps.first,
        'title': utf8.decode(maps.first['title']),
        'file_name': utf8.decode(maps.first['file_name']),
        'result': resultMap,
      });
    }
    return null;
  }

  static Future<void> deleteNote(int noteId) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
    await refreshNotes();
  }
  // Call this method when the app starts
  static void initStream() {
    refreshNotes();
  }

  // Call this method when the app is closing
  static void disposeStream() {
    _notesStreamController.close();
  }
}
