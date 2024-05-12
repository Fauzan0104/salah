import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // Path lokasi database
    String path = join(await getDatabasesPath(), 'users.db');

    // Buka atau buat database
    _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // Buat tabel users jika belum ada
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT,
          password TEXT
        )
      ''');
    });

    return _database!;
  }

  // Fungsi untuk menambahkan pengguna baru ke dalam tabel users
  static Future<void> insertUser(String email, String password) async {
    final Database db = await database;

    await db.insert(
      'users',
      {'email': email, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
