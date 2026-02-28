import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';

class UserService {
  final _supabase = Supabase.instance.client;
  final LocalDatabase _localDb = LocalDatabase();

  Future<void> fetchAndSyncProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final db = await _localDb.database;
        await db.insert('users', {
          'id': user.id,
          'email': user.email,
          'full_name': data['full_name'],
          'phone_number': data['phone_number'],
          'role': data['role'] ?? 'passenger',
          'is_synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      rethrow;
    }
  }
}
