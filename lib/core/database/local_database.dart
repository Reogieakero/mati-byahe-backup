library local_database;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

part 'local_database_trip.dart';
part 'local_database_report.dart';
part 'local_database_active_fare.dart';
part 'local_database_user.dart';

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
      version: 23,
      onCreate: (db, version) async => await _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 21) {
          try {
            await db.execute(
              'ALTER TABLE reports ADD COLUMN is_unreported INTEGER DEFAULT 0',
            );
          } catch (e) {}
        }
        if (oldVersion < 22) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN full_name TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN phone_number TEXT');
          } catch (e) {}
        }
        if (oldVersion < 23) {
          try {
            await db.execute(
              'ALTER TABLE users ADD COLUMN last_profile_update TEXT',
            );
          } catch (e) {}
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
        full_name TEXT,
        phone_number TEXT,
        role TEXT,
        last_profile_update TEXT,
        is_verified INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_fare(
        email TEXT PRIMARY KEY,
        fare REAL,
        pickup TEXT,
        drop_off TEXT,
        gas_tier TEXT,
        start_time TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE,
        passenger_id TEXT,
        driver_id TEXT,
        driver_name TEXT,
        email TEXT,
        pickup TEXT,
        drop_off TEXT,
        fare REAL,
        gas_tier TEXT,
        date TEXT,
        start_time TEXT,
        end_time TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await _createReportsTable(db);
  }

  Future<void> _createReportsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_uuid TEXT UNIQUE,
        passenger_id TEXT,
        driver_id TEXT,
        issue_type TEXT NOT NULL,
        description TEXT NOT NULL,
        evidence_url TEXT,
        status TEXT DEFAULT 'pending',
        reported_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        is_unreported INTEGER DEFAULT 0
      )
    ''');
  }
}
