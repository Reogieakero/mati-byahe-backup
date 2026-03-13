import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import '../core/services/trip_service.dart';
import '../signup/verification_screen.dart';
import '../components/confirmation_dialog.dart';
import '../core/widgets/sileo_notification.dart';

class HomeController {
  final LocalDatabase _localDb = LocalDatabase();
  final TripService _tripService = TripService();
  final _supabase = Supabase.instance.client;

  String _normalizePlate(dynamic value) {
    if (value == null) return '';
    return value.toString().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _tripPlate(Map<String, dynamic> trip) {
    return (trip['plate_number'] ?? trip['driver_plate'] ?? '').toString();
  }

  Future<bool> checkVerification(String email) async {
    final db = await _localDb.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    SyncService().syncOnStart();
    _tripService.syncTrips();
    return result.isNotEmpty && result.first['is_verified'] == 1;
  }

  Future<Map<String, dynamic>?> loadSavedFare(String email) async {
    return await _localDb.getActiveFare(email);
  }

  Future<void> startTrip({
    required BuildContext context,
    required String email,
    required double fare,
    required String pickup,
    required String dropOff,
    required String gasTier,
    required String driverPlate,
    required Function(double) onSuccess,
  }) async {
    final String startTime = DateTime.now().toIso8601String();
    await _localDb.saveActiveFare(
      email: email,
      fare: fare,
      pickup: pickup,
      dropOff: dropOff,
      gasTier: gasTier,
      startTime: startTime,
      driverPlate: driverPlate,
    );
    onSuccess(fare);
    showTripStartNotification(context);
  }

  Future<void> clearFare({
    required String email,
    required String pickup,
    required String dropOff,
    required String gasTier,
    required double fare,
    required String? startTime,
    required String driverName,
    required String driverPlate,
    required String? driverId,
    required Function() onCleared,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    final String endTime = DateTime.now().toIso8601String();
    String? resolvedPassengerId = currentUser?.id;

    if (resolvedPassengerId == null || resolvedPassengerId.isEmpty) {
      final db = await _localDb.database;
      final localUser = await db.query(
        'users',
        columns: ['id'],
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (localUser.isNotEmpty) {
        resolvedPassengerId = localUser.first['id']?.toString();
      }
    }

    if (currentUser != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': currentUser.id,
          'email': email,
        });
      } catch (e) {
        debugPrint("Profile sync skipped: $e");
      }
    }
    await _localDb.saveTrip(
      email: email,
      pickup: pickup,
      dropOff: dropOff,
      fare: fare,
      gasTier: gasTier,
      passengerId: resolvedPassengerId,
      driverPlate: driverPlate,
      driverId: driverId,
      driverName: driverName,
      startTime: startTime,
      endTime: endTime,
    );
    await _localDb.clearActiveFare(email);
    onCleared();
    Future.delayed(const Duration(seconds: 2), () {
      _tripService.syncTrips();
    });
  }

  Future<void> handleVerification({
    required BuildContext context,
    required String email,
    required Function(bool) setSendingState,
    required Function() onReturn,
  }) async {
    setSendingState(true);
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerificationScreen(email: email)),
      );
      onReturn();
    } catch (e) {
      if (context.mounted) {
        SileoNotification.show(
          context,
          'Failed to send code',
          type: SileoNoticeType.error,
        );
      }
    } finally {
      setSendingState(false);
    }
  }

  void confirmArrival(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ConfirmationDialog(
        title: "End Trip?",
        content: "Are you sure you have reached your destination?",
        confirmText: "Yes, Arrived",
        onConfirm: () {
          // This targets ONLY the dialog layer
          onConfirm();
        },
      ),
    );
  }

  void confirmChangeRoute(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ConfirmationDialog(
        title: "Change Route?",
        content: "This will cancel your current fare calculation. Continue?",
        confirmText: "Change",
        onConfirm: () {
          // This targets ONLY the dialog layer
          onConfirm();
        },
      ),
    );
  }

  void showTripStartNotification(BuildContext context) {
    SileoNotification.show(
      context,
      'Trip started. Safe travels and track your fare below.',
      type: SileoNoticeType.success,
    );
  }

  Future<Map<String, dynamic>> getDashboardStats({
    required String email,
    required String role,
  }) async {
    final db = await _localDb.database;
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (role.toLowerCase() == 'driver') {
      try {
        final currentUser = _supabase.auth.currentUser;
        String plateNumber = '';

        if (currentUser != null) {
          final profileById = await _supabase
              .from('profiles')
              .select('plate_number')
              .eq('id', currentUser.id)
              .maybeSingle();
          plateNumber = (profileById?['plate_number'] ?? '').toString().trim();
        }

        if (plateNumber.isEmpty) {
          final profileByEmail = await _supabase
              .from('profiles')
              .select('plate_number')
              .eq('email', email)
              .maybeSingle();
          plateNumber = (profileByEmail?['plate_number'] ?? '')
              .toString()
              .trim();
        }

        if (plateNumber.isNotEmpty) {
          final normalizedPlate = _normalizePlate(plateNumber);

          List<dynamic> response = [];
          try {
            response = await _supabase
                .from('trips')
                .select(
                  'passenger_id, plate_number, start_datetime, start_time, created_at, status',
                )
                .eq('status', 'completed')
                .order('created_at', ascending: false);
          } catch (_) {
            // Backward compatibility for workspaces where cloud still has driver_plate.
            response = await _supabase
                .from('trips')
                .select(
                  'passenger_id, driver_plate, start_datetime, start_time, created_at, status',
                )
                .eq('status', 'completed')
                .order('created_at', ascending: false);
          }

          // If no completed rows are visible, retry without status filter
          // to handle null/legacy statuses in existing data.
          if (response.isEmpty) {
            try {
              response = await _supabase
                  .from('trips')
                  .select(
                    'passenger_id, plate_number, start_datetime, start_time, created_at, status',
                  )
                  .order('created_at', ascending: false);
            } catch (_) {
              response = await _supabase
                  .from('trips')
                  .select(
                    'passenger_id, driver_plate, start_datetime, start_time, created_at, status',
                  )
                  .order('created_at', ascending: false);
            }
          }

          if (response.isNotEmpty) {
            final matchedTrips = response.where((trip) {
              return _normalizePlate(_tripPlate(trip)) == normalizedPlate;
            }).toList();

            final int todayTripCount = matchedTrips.where((trip) {
              final String dateSource =
                  (trip['start_datetime'] ??
                          trip['start_time'] ??
                          trip['created_at'] ??
                          '')
                      .toString();
              return dateSource.startsWith(today);
            }).length;

            final todayMatchedTrips = matchedTrips.where((trip) {
              final String dateSource =
                  (trip['start_datetime'] ??
                          trip['start_time'] ??
                          trip['created_at'] ??
                          '')
                      .toString();
              return dateSource.startsWith(today);
            }).toList();

            final int passengerCountToday = todayMatchedTrips
                .map((trip) => trip['passenger_id']?.toString())
                .where((id) => id != null && id.isNotEmpty)
                .toSet()
                .length;

            final int passengerCountTotal = matchedTrips
                .map((trip) => trip['passenger_id']?.toString())
                .where((id) => id != null && id.isNotEmpty)
                .toSet()
                .length;

            return {
              'count': todayTripCount,
              'plate': plateNumber,
              'passengers': passengerCountToday,
              'todayTrips': todayTripCount,
              'todayPassengers': passengerCountToday,
              'totalTrips': matchedTrips.length,
              'totalPassengers': passengerCountTotal,
            };
          }

          debugPrint(
            'Driver dashboard: no matching trips. profile plate=$plateNumber, rowsFetched=${response.length}',
          );
        }
      } catch (e) {
        debugPrint('Cloud fetch error (driver stats): $e');
      }

      // Last fallback for offline state: local stats by driver plate.
      final List<Map<String, dynamic>> localDriver = await db.query(
        'users',
        columns: ['plate_number'],
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      final String localPlate =
          (localDriver.isNotEmpty ? localDriver.first['plate_number'] : null)
              ?.toString()
              .trim() ??
          '';

      if (localPlate.isNotEmpty) {
        final normalizedLocalPlate = _normalizePlate(localPlate);
        final List<Map<String, dynamic>> localTrips = await db.query(
          'trips',
          columns: ['passenger_id', 'plate_number', 'start_time'],
        );

        final matchedLocalTrips = localTrips.where((trip) {
          return _normalizePlate(trip['plate_number']) == normalizedLocalPlate;
        }).toList();

        final int passengerCountToday = matchedLocalTrips
            .where((trip) {
              final String start = (trip['start_time'] ?? '').toString();
              return start.startsWith(today);
            })
            .map((trip) => trip['passenger_id']?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .toSet()
            .length;

        final int passengerCountTotal = matchedLocalTrips
            .map((trip) => trip['passenger_id']?.toString())
            .where((id) => id != null && id.isNotEmpty)
            .toSet()
            .length;

        final int todayTripCount = matchedLocalTrips.where((trip) {
          final String start = (trip['start_time'] ?? '').toString();
          return start.startsWith(today);
        }).length;

        return {
          'count': todayTripCount,
          'plate': localPlate,
          'passengers': passengerCountToday,
          'todayTrips': todayTripCount,
          'todayPassengers': passengerCountToday,
          'totalTrips': matchedLocalTrips.length,
          'totalPassengers': passengerCountTotal,
        };
      }

      return {
        'count': 0,
        'plate': 'None',
        'passengers': 0,
        'todayTrips': 0,
        'todayPassengers': 0,
        'totalTrips': 0,
        'totalPassengers': 0,
      };
    }

    // 1. Try fetching from Local SQLite first
    final List<Map<String, dynamic>> localTrips = await db.query(
      'trips',
      where:
          'passenger_id = (SELECT id FROM users WHERE email = ?) AND start_time LIKE ?',
      whereArgs: [email, '$today%'],
    );

    if (localTrips.isNotEmpty) {
      return {
        'count': localTrips.length,
        'plate': localTrips.last['plate_number'] ?? "None",
        'passengers': 0,
        'todayTrips': localTrips.length,
        'todayPassengers': 0,
        'totalTrips': localTrips.length,
        'totalPassengers': 0,
      };
    }

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {
          'count': 0,
          'plate': 'None',
          'passengers': 0,
          'todayTrips': 0,
          'todayPassengers': 0,
          'totalTrips': 0,
          'totalPassengers': 0,
        };
      }

      final response = await _supabase
          .from('trips')
          .select('plate_number')
          .eq('passenger_id', currentUser.id)
          .eq('status', 'completed')
          .gte('start_datetime', '${today}T00:00:00')
          .lte('start_datetime', '${today}T23:59:59');

      if (response.isNotEmpty) {
        return {
          'count': response.length,
          'plate': response.last['plate_number'] ?? "None",
          'passengers': 0,
          'todayTrips': response.length,
          'todayPassengers': 0,
          'totalTrips': response.length,
          'totalPassengers': 0,
        };
      }
    } catch (e) {
      debugPrint("Cloud fetch error: $e");
    }

    return {
      'count': 0,
      'plate': 'None',
      'passengers': 0,
      'todayTrips': 0,
      'todayPassengers': 0,
      'totalTrips': 0,
      'totalPassengers': 0,
    };
  }
}
