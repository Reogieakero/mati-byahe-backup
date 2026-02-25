import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_database.dart';
import '../models/user_model.dart';

class AuthService {
  final LocalDatabase _localDb = LocalDatabase();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> login(String email, String password) async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> localUsers = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (localUsers.isEmpty) return null;

    final user = UserModel.fromMap(localUsers.first);

    try {
      final internetResult = await InternetAddress.lookup('google.com');
      if (internetResult.isNotEmpty &&
          internetResult[0].rawAddress.isNotEmpty) {
        await _syncWithCloud(email, password, user.role);
      }
    } catch (_) {}

    return user;
  }

  Future<void> _syncWithCloud(
    String email,
    String password,
    String role,
  ) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.statusCode == '400') {
        await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {'role': role},
        );
      }
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
