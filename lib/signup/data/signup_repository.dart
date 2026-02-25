import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/local_database.dart';

class SignupRepository {
  final LocalDatabase localDb = LocalDatabase();
  final supabase = Supabase.instance.client;

  Future<void> registerUser(String email, String password, String role) async {
    final db = await localDb.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty && existing.first['is_verified'] == 1) {
      throw Exception("This email is already registered. Please log in!");
    }

    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'role': role},
      );

      if (res.user != null) {
        await supabase.from('profiles').upsert({
          'id': res.user!.id,
          'email': email,
          'role': role,
        });

        await db.insert('users', {
          'id': res.user!.id,
          'email': email,
          'password': password,
          'role': role,
          'is_verified': 0,
          'is_synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      if (e.toString().contains("SocketException") ||
          e.toString().contains("network")) {
        await db.insert('users', {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'email': email,
          'password': password,
          'role': role,
          'is_verified': 0,
          'is_synced': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        throw Exception("Offline: Account created locally!");
      }
      rethrow;
    }
  }

  Future<void> markAsVerified(String email) async {
    final db = await localDb.database;
    await db.update(
      'users',
      {'is_verified': 1},
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}
