import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String pathName = join(dbPath, 'byahe.db');

    return await openDatabase(
      pathName,
      version: 9, // Incremented to 9 to force the update
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Upgrade to version 7 logic (Active Fare)
        if (oldVersion < 7) {
          await db.execute('DROP TABLE IF EXISTS active_fare');
          await db.execute(
            'CREATE TABLE active_fare(email TEXT PRIMARY KEY, fare REAL)',
          );
        }

        // Upgrade to version 9 logic (Trips History)
        // This covers any version prior to 9, ensuring the table is created
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS trips(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT,
              pickup TEXT,
              drop_off TEXT,
              fare REAL,
              gas_tier TEXT,
              date TEXT,
              is_synced INTEGER DEFAULT 0
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        password TEXT,
        role TEXT,
        is_verified INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_fare(
        email TEXT PRIMARY KEY,
        fare REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT,
        pickup TEXT,
        drop_off TEXT,
        fare REAL,
        gas_tier TEXT,
        date TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> saveTrip({
    required String email,
    required String pickup,
    required String dropOff,
    required double fare,
    required String gasTier,
  }) async {
    final db = await database;
    await db.insert('trips', {
      'email': email,
      'pickup': pickup,
      'drop_off': dropOff,
      'fare': fare,
      'gas_tier': gasTier,
      'date': DateTime.now().toIso8601String(),
      'is_synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getTrips(String email) async {
    final db = await database;
    return await db.query(
      'trips',
      where: 'email = ?',
      whereArgs: [email],
      orderBy: 'date DESC',
    );
  }

  Future<void> saveActiveFare(String email, double fare) async {
    final db = await database;
    await db.insert('active_fare', {
      'email': email,
      'fare': fare,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<double?> getActiveFare(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'active_fare',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return maps.first['fare'] as double;
    }
    return null;
  }

  Future<void> clearActiveFare(String email) async {
    final db = await database;
    await db.delete('active_fare', where: 'email = ?', whereArgs: [email]);
  }
}
