import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tweetCreators (
        creatorUsername TEXT PRIMARY KEY,
        creatorName TEXT NOT NULL
      )
      ''');
  }

  Future<void> insertTweetCreator(Map<String, dynamic> tweetCreator) async {
    final db = await instance.database;
    await db.insert(
      'tweetCreators',
      tweetCreator,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getTweetCreators() async {
    final db = await instance.database;
    return await db.query('tweetCreators');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}