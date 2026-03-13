import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constant/app_colors.dart';
import '../../core/database/local_database.dart';
import '../../core/database/sync_service.dart';

enum TrackingFilter { today, yesterday, calendar }

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final supabase = Supabase.instance.client;
  final LocalDatabase _localDb = LocalDatabase();

  bool _isLoading = true;
  bool _isOffline = false;
  TrackingFilter _activeFilter = TrackingFilter.today;
  DateTime _selectedCalendarDate = DateTime.now();

  List<Map<String, dynamic>> _allPassengerTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];

  double _totalSpent = 0.0;
  int _completedTrips = 0;
  double _averageFare = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadTrips() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      if (!mounted) return;
      setState(() {
        _isOffline = true;
        _isLoading = false;
        _allPassengerTrips = [];
        _filteredTrips = [];
        _totalSpent = 0.0;
        _completedTrips = 0;
        _averageFare = 0.0;
      });
      return;
    }

    if (mounted) {
      setState(() => _isOffline = false);
    }

    try {
      await SyncService().syncOnStart().timeout(
        const Duration(seconds: 12),
        onTimeout: () {},
      );

      final userId = supabase.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allPassengerTrips = [];
          _filteredTrips = [];
          _totalSpent = 0.0;
          _completedTrips = 0;
          _averageFare = 0.0;
        });
        return;
      }

      final trips = await _localDb.getTripsByPassengerId(userId);
      final filtered = trips.where((trip) {
        final gasTier = (trip['gas_tier'] ?? '').toString().toUpperCase();
        return gasTier != 'N/A' && gasTier.isNotEmpty;
      }).toList();

      filtered.sort((a, b) {
        final dateA = _resolveTripDate(a) ?? DateTime(0);
        final dateB = _resolveTripDate(b) ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        _allPassengerTrips = filtered;
      });

      _applyFilter(_activeFilter, keepCalendarDate: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _resolveTripFare(Map<String, dynamic> trip) {
    final raw = trip['fare'] ?? trip['calculated_fare'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  DateTime? _resolveTripDate(Map<String, dynamic> trip) {
    final possible = [
      trip['start_datetime'],
      trip['start_time'],
      trip['date'],
      trip['created_at'],
    ];

    for (final source in possible) {
      if (source == null) continue;
      try {
        return DateTime.parse(source.toString()).toLocal();
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  void _applyFilter(
    TrackingFilter filter, {
    DateTime? calendarDate,
    bool keepCalendarDate = false,
  }) {
    final now = DateTime.now();
    final selectedDate = keepCalendarDate
        ? _selectedCalendarDate
        : (calendarDate ?? _selectedCalendarDate);

    DateTime targetDate;
    if (filter == TrackingFilter.today) {
      targetDate = DateTime(now.year, now.month, now.day);
    } else if (filter == TrackingFilter.yesterday) {
      final y = now.subtract(const Duration(days: 1));
      targetDate = DateTime(y.year, y.month, y.day);
    } else {
      targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    }

    final filtered = _allPassengerTrips.where((trip) {
      final tripDate = _resolveTripDate(trip);
      if (tripDate == null) return false;
      return DateUtils.isSameDay(tripDate, targetDate);
    }).toList();

    double total = 0.0;
    for (final trip in filtered) {
      total += _resolveTripFare(trip);
    }

    final tripCount = filtered.length;

    setState(() {
      _activeFilter = filter;
      if (filter == TrackingFilter.calendar) {
        _selectedCalendarDate = targetDate;
      }
      _filteredTrips = filtered;
      _totalSpent = total;
      _completedTrips = tripCount;
      _averageFare = tripCount == 0 ? 0.0 : (total / tripCount);
    });
  }

  Future<void> _pickCalendarDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedCalendarDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );

    if (picked == null) return;
    _applyFilter(TrackingFilter.calendar, calendarDate: picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.darkNavy,
                  strokeWidth: 2,
                ),
              )
            : RefreshIndicator(
                color: AppColors.darkNavy,
                onRefresh: _loadTrips,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: _isOffline
                      ? [_buildOfflineState()]
                      : [
                          const Text(
                            'PASSENGER TRACKING',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkNavy,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFilterRow(),
                          const SizedBox(height: 14),
                          _buildTrackingScoreCard(),
                          const SizedBox(height: 16),
                          _buildSummaryCards(),
                          const SizedBox(height: 18),
                          Text(
                            _activeFilter == TrackingFilter.calendar
                                ? 'Trips on ${DateFormat('MMM dd, yyyy').format(_selectedCalendarDate)}'
                                : 'Trip Spending',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNavy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_filteredTrips.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'No trip records for this filter yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ..._filteredTrips.map(_buildTripTile),
                        ],
                ),
              ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Icon(Icons.wifi_off_rounded, size: 42, color: AppColors.textGrey),
          SizedBox(height: 10),
          Text(
            'Need internet to show tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Please connect to the internet then pull to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _filterButton(
                label: 'Today',
                selected: _activeFilter == TrackingFilter.today,
                onTap: () => _applyFilter(TrackingFilter.today),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterButton(
                label: 'Yesterday',
                selected: _activeFilter == TrackingFilter.yesterday,
                onTap: () => _applyFilter(TrackingFilter.yesterday),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterButton(
                label: 'Calendar',
                selected: _activeFilter == TrackingFilter.calendar,
                onTap: () async {
                  await _pickCalendarDate();
                },
              ),
            ),
          ],
        ),
        if (_activeFilter == TrackingFilter.calendar) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickCalendarDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: AppColors.darkNavy,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'EEE, MMM dd, yyyy',
                    ).format(_selectedCalendarDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _filterButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkNavy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.darkNavy
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.darkNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingScoreCard() {
    final bool isToday = _activeFilter == TrackingFilter.today;
    final double target = isToday ? 600.0 : 500.0;
    final double spendRatio = (_totalSpent / target).clamp(0, 1);
    final int score = (100 - (spendRatio * 100)).round().clamp(0, 100);
    final double progress = (score / 100).clamp(0, 1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 7,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.15),
                  ),
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.greenAccent,
                  ),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PHP ${_totalSpent.toStringAsFixed(0)} spent',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Budget target: PHP ${target.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _summaryItem(
          label: 'Spent',
          value: 'PHP ${_totalSpent.toStringAsFixed(0)}',
          valueColor: Colors.redAccent,
        ),
        const SizedBox(width: 10),
        _summaryItem(
          label: 'Trips',
          value: '$_completedTrips',
          valueColor: Colors.orangeAccent,
        ),
        const SizedBox(width: 10),
        _summaryItem(
          label: 'Avg Cost',
          value: 'PHP ${_averageFare.toStringAsFixed(0)}',
          valueColor: Colors.green,
        ),
      ],
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTile(Map<String, dynamic> trip) {
    final fare = _resolveTripFare(trip);

    String when = 'Unknown date';
    final date = _resolveTripDate(trip);
    if (date != null) {
      when = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    }

    final pickup = (trip['pickup'] ?? 'Unknown').toString();
    final dropOff = (trip['drop_off'] ?? 'Unknown').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  when,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey.withOpacity(0.7),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pickup → $dropOff',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '-₱${fare.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
