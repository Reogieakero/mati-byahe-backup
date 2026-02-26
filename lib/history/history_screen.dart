import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/services/trip_service.dart';
import 'widgets/history_header.dart';
import 'widgets/history_tile.dart';
import '../components/confirmation_dialog.dart';

class HistoryScreen extends StatefulWidget {
  final String email;
  const HistoryScreen({super.key, required this.email});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TripService _tripService = TripService();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    await _tripService.syncTrips();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryYellow.withOpacity(0.2),
              Colors.white,
              AppColors.primaryYellow.withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            const HistoryHeader(),
            Expanded(
              child: userId == null
                  ? _buildEmptyState()
                  : FutureBuilder<List<Map<String, dynamic>>>(
                      future: LocalDatabase().getTripsByPassengerId(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error loading history"),
                          );
                        }

                        final trips = snapshot.data ?? [];

                        if (trips.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: _triggerSync,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: trips.length,
                            itemBuilder: (context, index) {
                              final trip = trips[index];
                              return HistoryTile(
                                trip: trip,
                                onDelete: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => ConfirmationDialog(
                                      title: "Delete Trip",
                                      content:
                                          "Are you sure you want to delete this trip record? This cannot be undone.",
                                      confirmText: "Delete",
                                      onConfirm: () async {
                                        await _tripService.deleteTrip(
                                          trip['uuid'],
                                        );
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  );
                                },
                                onViewDetails: () {},
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 60,
            color: AppColors.darkNavy.withOpacity(0.2),
          ),
          const SizedBox(height: 10),
          const Text(
            "No past trips found",
            style: TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
