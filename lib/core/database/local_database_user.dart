part of 'local_database.dart';

extension UserDatabase on LocalDatabase {
  Future<void> updateUserProfile({
    required String id,
    required String name,
    required String phone,
  }) async {
    final db = await database;
    await db.update(
      'users',
      {
        'full_name': name,
        'phone_number': phone,
        'last_profile_update': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
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
