import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_database.dart';
import '../models/user_model.dart';
import 'package:sqflite/sqflite.dart'; // Add this for ConflictAlgorithm

class AuthService {
  final LocalDatabase _localDb = LocalDatabase();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> login(String email, String password) async {
    try {
      // 1. TRY CLOUD LOGIN FIRST
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Get the role from Supabase metadata (stored during registration)
        final String role = res.user!.userMetadata?['role'] ?? 'passenger';

        // 2. RE-SYNC LOCAL DATABASE
        // This "heals" the app after a reinstall by putting the user back in SQLite
        final db = await _localDb.database;
        await db.insert('users', {
          'id': res.user!.id,
          'email': email,
          'password':
              password, // Optional: only if you need offline login later
          'role': role,
          'is_verified': 1,
          'is_synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        return UserModel(email: email, role: role);
      }
    } on AuthException catch (e) {
      // If cloud login fails (e.g., wrong password or no internet),
      // check the local database as a fallback
      print("Cloud login failed: ${e.message}");
      return await _attemptLocalLogin(email, password);
    } catch (e) {
      return await _attemptLocalLogin(email, password);
    }
    return null;
  }

  // Fallback for offline login
  Future<UserModel?> _attemptLocalLogin(String email, String password) async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> localUsers = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (localUsers.isNotEmpty) {
      return UserModel.fromMap(localUsers.first);
    }
    return null;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
