import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

class SyncService {
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;

  Future<void> syncOnStart() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (result.isEmpty || result[0].rawAddress.isEmpty) return;

      final db = await _localDb.database;

      await pullUserData();
      await _syncProfileChanges(db);
      await _syncTrips(db);
      await _syncReports(db);
      await _syncDeletedReports(db);
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  Future<void> pullUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final db = await _localDb.database;

    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        await db.insert('users', {
          'id': profile['id'],
          'full_name': profile['full_name'],
          'phone_number': profile['phone_number'],
          'role': profile['role'],
          'email': user.email,
          'is_verified': 1,
          'is_synced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final trips = await _supabase
          .from('trips')
          .select()
          .or('passenger_id.eq.${user.id},driver_id.eq.${user.id}');

      if (trips != null) {
        for (var trip in trips) {
          await db.insert('trips', {
            'uuid': trip['uuid'],
            'passenger_id': trip['passenger_id'],
            'driver_id': trip['driver_id'],
            'driver_name': trip['driver_name'],
            'driver_plate': trip['driver_plate'],
            'pickup': trip['pickup'],
            'drop_off': trip['drop_off'],
            'fare': trip['calculated_fare'],
            'gas_tier': trip['gas_tier'],
            'start_time': trip['start_datetime'],
            'end_time': trip['end_datetime'],
            'is_synced': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      debugPrint("Pull error: $e");
    }
  }

  Future<void> _syncProfileChanges(db) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final List<Map<String, dynamic>> unsynced = await db.query(
      'users',
      where: 'id = ? AND is_synced = ?',
      whereArgs: [currentUser.id, 0],
    );

    if (unsynced.isEmpty) return;
    final userData = unsynced.first;
    if (userData['role'] == null || userData['role'] == 'Unknown') return;

    try {
      await _supabase.from('profiles').upsert({
        'id': userData['id'],
        'full_name': userData['full_name'],
        'phone_number': userData['phone_number'],
        'role': userData['role'],
        'login_pin': userData['login_pin'],
        'updated_at': DateTime.now().toIso8601String(),
      });

      await db.update(
        'users',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [userData['id']],
      );
    } catch (e) {}
  }

  Future<void> _syncTrips(db) async {
    final List<Map<String, dynamic>> unsynced = await db.query(
      'trips',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (var data in unsynced) {
      try {
        await _supabase.from('trips').upsert({
          'uuid': data['uuid'],
          'passenger_id': data['passenger_id'],
          'driver_id': data['driver_id'],
          'driver_name': data['driver_name'],
          'driver_plate': data['driver_plate'],
          'pickup': data['pickup'] ?? 'Unknown',
          'drop_off': data['drop_off'] ?? '',
          'calculated_fare': data['fare'] ?? 0.0,
          'gas_tier': data['gas_tier'],
          'start_time': data['start_datetime'],
          'end_time': data['end_datetime'],
          'status': data['end_datetime'] != null ? 'completed' : 'active',
        }, onConflict: 'uuid');

        await db.update(
          'trips',
          {'is_synced': 1},
          where: 'uuid = ?',
          whereArgs: [data['uuid']],
        );
      } catch (e) {
        debugPrint("Sync failed for trip ${data['uuid']}: $e");
      }
    }
  }

  Future<void> _syncReports(db) async {
    final List<Map<String, dynamic>> unsynced = await db.query(
      'reports',
      where: 'is_synced = ? AND is_deleted = ?',
      whereArgs: [0, 0],
    );
    for (var data in unsynced) {
      try {
        await _supabase.from('reports').upsert({
          'trip_uuid': data['trip_uuid'],
          'issue_type': data['issue_type'],
          'description': data['description'],
          'status': data['status'],
          'reported_at': data['reported_at'],
        }, onConflict: 'trip_uuid');
        await db.update(
          'reports',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [data['id']],
        );
      } catch (e) {
        debugPrint("SUPABASE REPORT SYNC ERROR: $e");
      }
    }
  }

  Future<void> _syncDeletedReports(db) async {
    final List<Map<String, dynamic>> deleted = await db.query(
      'reports',
      where: 'is_deleted = ?',
      whereArgs: [1],
    );
    for (var data in deleted) {
      try {
        await _supabase
            .from('reports')
            .delete()
            .eq('trip_uuid', data['trip_uuid']);
        await db.delete('reports', where: 'id = ?', whereArgs: [data['id']]);
      } catch (e) {}
    }
  }
}
