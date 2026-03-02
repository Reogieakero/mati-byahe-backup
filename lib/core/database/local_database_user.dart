part of 'local_database.dart';

extension UserDatabase on LocalDatabase {
  Future<void> updateUserProfile({
    required String id,
    required String name,
    required String phone,
    String? plate,
    String? color,
    String? address,
    String? license,
    String? vehicleType,
  }) async {
    final db = await database;
    await db.update(
      'users',
      {
        'full_name': name,
        'phone_number': phone,
        'plate_number': plate,
        'vehicle_color': color,
        'address': address,
        'license_number': license,
        'vehicle_type': vehicleType,
        'last_profile_update': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLocalPin(String id, String pin) async {
    final db = await database;
    await db.update(
      'users',
      {'login_pin': pin, 'is_synced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }
}
