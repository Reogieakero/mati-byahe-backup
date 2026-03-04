part of 'local_database.dart';

extension TripDatabase on LocalDatabase {
  /// Saves a trip locally.
  ///
  /// If [uuid] is provided we will use that value; otherwise a new one is
  /// generated. The generated or provided uuid is returned so callers can
  /// later update the same record (for example when completing the trip).
  Future<String> saveTrip({
    String? uuid,
    required String email,
    required String pickup,
    required String dropOff,
    required double fare,
    required String gasTier,
    String? passengerId,
    String? driverId,
    String? driverName,
    String? driverPlate,
    String? startTime,
    String? endTime,
  }) async {
    final db = await database;
    final tripUuid = uuid ?? const Uuid().v4();
    await db.insert('trips', {
      'uuid': tripUuid,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_plate': driverPlate,
      'email': email,
      'pickup': pickup,
      'drop_off': dropOff,
      'fare': fare,
      'gas_tier': gasTier,
      'date': DateTime.now().toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'is_synced': 0,
    });
    return tripUuid;
  }

  Future<void> updateTripEnd({
    required String uuid,
    required String dropOff,
    String? endTime,
  }) async {
    final db = await database;
    await db.update(
      'trips',
      {'drop_off': dropOff, 'end_time': endTime, 'is_synced': 0},
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
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

  Future<List<Map<String, dynamic>>> getTripsByPassengerId(
    String passengerId,
  ) async {
    final db = await database;
    return await db.query(
      'trips',
      where: 'passenger_id = ?',
      whereArgs: [passengerId],
      orderBy: 'date DESC',
    );
  }

  Future<int> deleteTrip(String uuid) async {
    final db = await database;
    return await db.delete('trips', where: 'uuid = ?', whereArgs: [uuid]);
  }
}
