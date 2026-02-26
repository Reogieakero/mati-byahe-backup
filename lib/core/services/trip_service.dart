import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/local_database.dart';

class TripService {
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;

  Future<void> syncTrips() async {
    try {
      final db = await _localDb.database;
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // 1. PUSH: Sync local trips to cloud
      final List<Map<String, dynamic>> unsynced = await db.query(
        'trips',
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      for (var data in unsynced) {
        try {
          await _supabase.from('trips').insert({
            'uuid': data['uuid'],
            'passenger_id': currentUser.id, // Using active session ID
            'driver_id': data['driver_id'],
            'pickup': data['pickup'],
            'drop_off': data['drop_off'],
            'calculated_fare': data['fare'],
            'gas_tier': data['gas_tier'],
            'start_datetime': data['start_time'],
            'end_datetime': data['end_time'],
            'created_at': data['date'],
            'status': 'completed',
          });
          await db.update(
            'trips',
            {'is_synced': 1},
            where: 'id = ?',
            whereArgs: [data['id']],
          );
        } catch (e) {
          continue;
        }
      }

      // 2. PULL: Fetch from cloud based on passenger_id (UUID)
      final cloudTrips = await _supabase
          .from('trips')
          .select()
          .eq('passenger_id', currentUser.id) // Query by UUID
          .order('created_at', ascending: false);

      for (var cloudTrip in cloudTrips) {
        final localExists = await db.query(
          'trips',
          where: 'uuid = ?',
          whereArgs: [cloudTrip['uuid']],
        );

        if (localExists.isEmpty) {
          await db.insert('trips', {
            'uuid': cloudTrip['uuid'],
            'passenger_id': cloudTrip['passenger_id'], // Store UUID locally
            'email': currentUser.email,
            'driver_id': cloudTrip['driver_id'],
            'pickup': cloudTrip['pickup'],
            'drop_off': cloudTrip['drop_off'],
            'fare': cloudTrip['calculated_fare'],
            'gas_tier': cloudTrip['gas_tier'],
            'start_time': cloudTrip['start_datetime'],
            'end_time': cloudTrip['end_datetime'],
            'date': cloudTrip['created_at'],
            'is_synced': 1,
          });
        }
      }
    } catch (e) {
      print("Sync Error: $e");
    }
  }

  Future<void> deleteTrip(String uuid) async {
    try {
      await _supabase.from('trips').delete().eq('uuid', uuid);

      await _localDb.deleteTrip(uuid);
    } catch (e) {
      await _localDb.deleteTrip(uuid);
      print("Cloud delete failed, but local trip removed: $e");
    }
  }
}
