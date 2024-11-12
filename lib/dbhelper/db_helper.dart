import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    final noteData = {
      'title': note['title'],
      'content': note['content'],
      'dateTime': note['createdAt'],
      'priority': note['priority'],
      'category': note['category'],
      'isArchived': 0 
      
    };
    return await db.insert('notes', noteData);
  }

  Future<int> updateNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    final noteData = {
      'title': note['title'],
      'content': note['content'],
      'dateTime': note['updatedAt'],
      'priority': note['priority'],
      'category': note['category']
    };
    return await db.update(
      'notes',
      noteData,
      where: 'id = ?',
      whereArgs: [note['id']],
    );
  }

  Future<List<Map<String, dynamic>>> getNotes({bool archived = false}) async {
    final db = await instance.database;
    final notes = await db.query(
      'notes',
      where: 'isArchived = ?',
      whereArgs: [archived ? 1 : 0],
    );
    return notes.map((note) {
      return {
        ...note,
        'createdAt': note['dateTime'],
        'updatedAt': note['dateTime'],
        'isArchived': note['isArchived'] == 1,
      };
    }).toList();
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> archiveNote(int id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'isArchived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> unarchiveNote(int id) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'isArchived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
