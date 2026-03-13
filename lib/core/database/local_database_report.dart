part of 'local_database.dart';

extension ReportDatabase on LocalDatabase {
  Future<void> saveReport({
    required String tripUuid,
    required String passengerId,
    required String driverId,
    required String issueType,
    required String description,
    String? evidencePath,
    String status = 'pending',
    String? reportedAt,
    int isSynced = 0,
  }) async {
    final db = await database;
    await db.insert('reports', {
      'trip_uuid': tripUuid,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'issue_type': issueType,
      'description': description,
      'evidence_url': evidencePath,
      'status': status,
      'reported_at': reportedAt ?? DateTime.now().toIso8601String(),
      'is_synced': isSynced,
      'is_deleted': 0,
      'is_unreported': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getReportHistory(
    String passengerId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        r.*, 
        t.pickup, 
        t.drop_off, 
        t.driver_name,
        t.plate_number,
        t.start_time,
        t.end_time
      FROM reports r
      LEFT JOIN trips t ON r.trip_uuid = t.uuid
      WHERE r.passenger_id = ? 
        AND r.is_deleted = 0 
        AND r.is_unreported = 0
      ORDER BY r.id DESC
    ''',
      [passengerId],
    );
  }

  Future<List<Map<String, dynamic>>> getReportsForDriver(
    String driverId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        r.*, 
        t.pickup, 
        t.drop_off, 
        t.driver_name,
        t.plate_number,
        t.start_time,
        t.end_time
      FROM reports r
      LEFT JOIN trips t ON r.trip_uuid = t.uuid
      WHERE r.driver_id = ? 
        AND r.is_deleted = 0 
      ORDER BY r.id DESC
    ''',
      [driverId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllDriverVisibleReports() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        r.*, 
        t.pickup, 
        t.drop_off, 
        t.driver_name,
        t.plate_number,
        t.start_time,
        t.end_time
      FROM reports r
      LEFT JOIN trips t ON r.trip_uuid = t.uuid
      WHERE r.is_deleted = 0
      ORDER BY r.id DESC
    ''');
  }

  Future<int> deleteReportPermanently(int id) async {
    final db = await database;
    return await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markReportAsDeleted(int id) async {
    final db = await database;
    await db.update(
      'reports',
      {'is_deleted': 1, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsUnreported(int id) async {
    final db = await database;
    await db.update(
      'reports',
      {'is_unreported': 1, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllReports() async {
    final db = await database;
    await db.delete('reports');
  }

  Future<bool> isTripReported(String tripUuid) async {
    final db = await database;
    final result = await db.query(
      'reports',
      where: 'trip_uuid = ? AND is_unreported = 0 AND is_deleted = 0',
      whereArgs: [tripUuid],
    );
    return result.isNotEmpty;
  }
}
