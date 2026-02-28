import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_database.dart';
import '../models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final LocalDatabase _localDb = LocalDatabase();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> login(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final profileData = await _supabase
            .from('profiles')
            .select('full_name, phone_number, role')
            .eq('id', res.user!.id)
            .maybeSingle();

        final String role = profileData?['role'] ?? 'Unknown';

        final db = await _localDb.database;
        await db.insert('users', {
          'id': res.user!.id,
          'email': email,
          'password': password,
          'full_name': profileData?['full_name'],
          'phone_number': profileData?['phone_number'],
          'role': role,
          'is_verified': 1,
          'is_synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        await syncDownTransactions(res.user!.id);
        await syncDownReports(res.user!.id);

        return UserModel(email: email, role: role);
      }
    } catch (e) {
      return await _attemptLocalLogin(email, password);
    }
    return null;
  }

  Future<void> syncDownTransactions(String userId) async {
    final db = await _localDb.database;
    try {
      final response = await _supabase
          .from('trips')
          .select()
          .or('passenger_id.eq.$userId,driver_id.eq.$userId');

      if (response != null) {
        for (var record in (response as List)) {
          await db.insert('trips', {
            'uuid': record['uuid'],
            'passenger_id': record['passenger_id'],
            'driver_id': record['driver_id'],
            'driver_name': record['driver_name'],
            'email': record['email'] ?? '',
            'pickup': record['pickup'],
            'drop_off': record['drop_off'],
            'fare': record['calculated_fare'],
            'gas_tier': record['gas_tier'],
            'date': record['created_at'],
            'start_time': record['start_datetime'],
            'end_time': record['end_datetime'],
            'is_synced': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      debugPrint("Trip Sync Error: $e");
    }
  }

  Future<void> syncDownReports(String userId) async {
    final db = await _localDb.database;
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .or('passenger_id.eq.$userId,driver_id.eq.$userId');

      if (response != null) {
        for (var record in (response as List)) {
          await db.insert('reports', {
            'trip_uuid': record['trip_uuid'],
            'passenger_id': record['passenger_id'],
            'driver_id': record['driver_id'],
            'issue_type': record['issue_type'],
            'description': record['description'],
            'evidence_url': record['evidence_url'],
            'status': record['status'],
            'reported_at': record['reported_at'],
            'is_synced': 1,
            'is_deleted': 0,
            'is_unreported': record['is_unreported'] == true ? 1 : 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      debugPrint("Report Sync Error: $e");
    }
  }

  Future<UserModel?> _attemptLocalLogin(String email, String password) async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> localUsers = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (localUsers.isNotEmpty) return UserModel.fromMap(localUsers.first);
    return null;
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> users = await db.query('users', limit: 1);
    return users.isNotEmpty ? users.first : null;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final db = await _localDb.database;
    await db.delete('users');
    await db.delete('trips');
    await db.delete('reports');
  }
}
