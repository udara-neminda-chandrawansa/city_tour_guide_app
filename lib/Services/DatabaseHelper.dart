import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('city_tour_guide.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        username TEXT
      )
    ''');

    // Create attractions table
    await db.execute('''
      CREATE TABLE attractions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        rating REAL,
        image_url TEXT
      )
    ''');

    // Create bookmarks table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attraction_id INTEGER,
        user_id INTEGER,
        FOREIGN KEY (attraction_id) REFERENCES attractions (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // User-related database methods
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email]
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Attraction-related database methods
  Future<int> insertAttraction(Map<String, dynamic> attraction) async {
    final db = await database;
    return await db.insert('attractions', attraction);
  }

  Future<List<Map<String, dynamic>>> getAttractions({String? category}) async {
    final db = await database;
    return category != null
        ? await db.query('attractions', where: 'category = ?', whereArgs: [category])
        : await db.query('attractions');
  }

  // Bookmark-related database methods
  Future<int> addBookmark(int userId, int attractionId) async {
    final db = await database;
    return await db.insert('bookmarks', {
      'user_id': userId,
      'attraction_id': attractionId
    });
  }

  Future<List<Map<String, dynamic>>> getUserBookmarks(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT a.* FROM attractions a
      JOIN bookmarks b ON a.id = b.attraction_id
      WHERE b.user_id = ?
    ''', [userId]);
  }
}