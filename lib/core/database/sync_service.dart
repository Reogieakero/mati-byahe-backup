import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database.dart';

class SyncService {
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;

  Future<void> syncOnStart() async {
    final db = await _localDb.database;

    final List<Map<String, dynamic>> unsyncedUsers = await db.query(
      'users',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    if (unsyncedUsers.isEmpty) return;

    for (var user in unsyncedUsers) {
      try {
        String? supabaseUid;

        try {
          final AuthResponse res = await _supabase.auth.signUp(
            email: user['email'],
            password: user['password'],
          );
          supabaseUid = res.user?.id;
        } on AuthException catch (ae) {
          if (ae.message.contains('already registered')) {
            final AuthResponse loginRes = await _supabase.auth
                .signInWithPassword(
                  email: user['email'],
                  password: user['password'],
                );
            supabaseUid = loginRes.user?.id;
          } else {
            rethrow;
          }
        }

        if (supabaseUid != null) {
          await _supabase.from('profiles').upsert({
            'id': supabaseUid,
            'email': user['email'],
            'role': user['role'],
          });

          await db.update(
            'users',
            {'is_synced': 1, 'id': supabaseUid},
            where: 'email = ?',
            whereArgs: [user['email']],
          );
        }
      } catch (e) {
        continue;
      }
    }
  }
}
