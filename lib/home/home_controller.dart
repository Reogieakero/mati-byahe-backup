import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import '../core/services/trip_service.dart';
import '../core/constant/app_colors.dart';
import '../signup/verification_screen.dart';
import '../components/confirmation_dialog.dart';

class HomeController {
  final LocalDatabase _localDb = LocalDatabase();
  final TripService _tripService = TripService();
  final _supabase = Supabase.instance.client;

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
    required Function() onCleared,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    const String mockDriver = "Lito Lapid";
    final String endTime = DateTime.now().toIso8601String();

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
      passengerId: currentUser?.id,
      driverName: mockDriver,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to send code")));
      }
    } finally {
      setSendingState(false);
    }
  }

  void confirmArrival(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "End Trip?",
        content: "Are you sure you have reached your destination?",
        confirmText: "Yes, Arrived",
        onConfirm: onConfirm,
      ),
    );
  }

  void confirmChangeRoute(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Change Route?",
        content: "This will cancel your current fare calculation. Continue?",
        confirmText: "Change",
        onConfirm: onConfirm,
      ),
    );
  }

  void showTripStartNotification(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 15,
        right: 15,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 500),
            tween: Tween<double>(begin: -100, end: 0),
            curve: Curves.easeOutBack,
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bolt,
                          color: AppColors.darkNavy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Trip Started",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Safe travels! Track your fare below.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }
}
