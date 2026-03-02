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
      version: 26, // Incremented version
      onCreate: (db, version) async => await _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 26) {
          try {
            await db.execute('ALTER TABLE users ADD COLUMN plate_number TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN vehicle_color TEXT');
            await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
            await db.execute(
              'ALTER TABLE users ADD COLUMN license_number TEXT',
            );
            await db.execute('ALTER TABLE users ADD COLUMN vehicle_type TEXT');
          } catch (e) {}
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id TEXT PRIMARY KEY,
        email TEXT,
        full_name TEXT,
        phone_number TEXT,
        role TEXT,
        plate_number TEXT,
        vehicle_color TEXT,
        address TEXT,
        license_number TEXT,
        vehicle_type TEXT,
        login_pin TEXT,
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
        reported_at TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
  }
}
