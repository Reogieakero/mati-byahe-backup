import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/services/trip_service.dart';
import 'widgets/history_header.dart';
import 'widgets/history_tile.dart';
import 'widgets/history_empty_state.dart';
import 'history_details_screen.dart';
import '../../components/confirmation_dialog.dart';

class HistoryScreen extends StatefulWidget {
  final String email;
  const HistoryScreen({super.key, required this.email});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TripService _tripService = TripService();
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _triggerSync();
  }

  Future<void> _triggerSync() async {
    await _tripService.syncTrips();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final trips = await LocalDatabase().getTripsByPassengerId(userId);
      if (mounted) {
        setState(() {
          var filtered = trips.where((trip) {
            final String gasTier = (trip['gas_tier'] ?? "")
                .toString()
                .toUpperCase();
            return gasTier != "N/A" && gasTier.isNotEmpty;
          }).toList();

          filtered.sort((a, b) {
            DateTime dateA =
                DateTime.tryParse(a['start_time'] ?? '') ?? DateTime(0);
            DateTime dateB =
                DateTime.tryParse(b['start_time'] ?? '') ?? DateTime(0);
            return dateB.compareTo(dateA);
          });

          _allTrips = filtered;
          _filteredTrips = filtered;
        });
      }
    }
  }

  void _filterTrips(String query) {
    setState(() {
      _filteredTrips = _allTrips.where((trip) {
        final pickup = (trip['pickup'] ?? "").toString().toLowerCase();
        final dropOff = (trip['drop_off'] ?? "").toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return pickup.contains(searchLower) || dropOff.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const HistoryHeader(),
          _buildSearchBar(),
          Expanded(
            child: userId == null
                ? _buildScrollableEmptyState()
                : _allTrips.isEmpty
                ? _buildScrollableEmptyState()
                : RefreshIndicator(
                    color: AppColors.darkNavy,
                    onRefresh: _triggerSync,
                    child: _filteredTrips.isEmpty
                        ? _buildNoResultsFound()
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemCount: _filteredTrips.length,
                            itemBuilder: (context, index) {
                              final trip = _filteredTrips[index];
                              return HistoryTile(
                                trip: trip,
                                onViewDetails: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HistoryDetailsScreen(trip: trip),
                                    ),
                                  );
                                },
                                onDelete: () => _handleDelete(trip),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterTrips,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Search location...",
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 15, right: 10),
            child: Icon(Icons.search, size: 20, color: AppColors.darkNavy),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _filterTrips("");
                  },
                )
              : null,
          filled: false,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: AppColors.textGrey.withOpacity(0.3),
          ),
          const SizedBox(height: 10),
          Text(
            "No matching trips found",
            style: TextStyle(
              color: AppColors.textGrey.withOpacity(0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDelete(Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Delete Trip",
        content: "Are you sure you want to delete this trip record?",
        confirmText: "Delete",
        onConfirm: () async {
          await _tripService.deleteTrip(trip['uuid']);
          _loadTrips();
        },
      ),
    );
  }

  Widget _buildScrollableEmptyState() {
    return RefreshIndicator(
      color: AppColors.darkNavy,
      onRefresh: _triggerSync,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: const HistoryEmptyState(),
          ),
        ],
      ),
    );
  }
}
