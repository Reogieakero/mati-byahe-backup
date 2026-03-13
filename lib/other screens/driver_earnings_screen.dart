import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';

enum EarningsFilter { today, yesterday, calendar }

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with AutomaticKeepAliveClientMixin {
  final LocalDatabase _localDb = LocalDatabase();
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  EarningsFilter _activeFilter = EarningsFilter.today;
  DateTime _selectedCalendarDate = DateTime.now();

  List<Map<String, dynamic>> _allDriverTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];

  double _totalEarnings = 0.0;
  int _completedTrips = 0;
  double _averageFare = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  String _normalizePlate(dynamic value) {
    return (value ?? '').toString().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
  }

  Future<String> _resolveDriverPlate(String driverId) async {
    final db = await _localDb.database;

    final localRows = await db.query(
      'users',
      columns: ['plate_number'],
      where: 'id = ?',
      whereArgs: [driverId],
      limit: 1,
    );

    final localPlate = localRows.isNotEmpty
        ? (localRows.first['plate_number'] ?? '').toString().trim()
        : '';
    if (localPlate.isNotEmpty) return localPlate;

    try {
      final profile = await supabase
          .from('profiles')
          .select('plate_number')
          .eq('id', driverId)
          .maybeSingle();
      return (profile?['plate_number'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCloudTripsByPlate(
    String normalizedPlate,
  ) async {
    if (normalizedPlate.isEmpty) return [];

    const modernCalculatedFareSelect =
        'uuid,id,driver_id, plate_number, pickup, drop_off, calculated_fare, start_datetime, start_time, created_at, status';
    const legacyCalculatedFareSelect =
        'uuid,id,driver_id, driver_plate, pickup, drop_off, calculated_fare, start_datetime, start_time, created_at, status';
    const modernFareSelect =
        'uuid,id,driver_id, plate_number, pickup, drop_off, fare, start_datetime, start_time, created_at, status';
    const legacyFareSelect =
        'uuid,id,driver_id, driver_plate, pickup, drop_off, fare, start_datetime, start_time, created_at, status';

    List<dynamic> response = [];
    try {
      response = await supabase
          .from('trips')
          .select(modernCalculatedFareSelect)
          .eq('status', 'completed')
          .order('created_at', ascending: false);
    } catch (_) {
      try {
        response = await supabase
            .from('trips')
            .select(legacyCalculatedFareSelect)
            .eq('status', 'completed')
            .order('created_at', ascending: false);
      } catch (_) {
        try {
          response = await supabase
              .from('trips')
              .select(modernFareSelect)
              .eq('status', 'completed')
              .order('created_at', ascending: false);
        } catch (_) {
          response = await supabase
              .from('trips')
              .select(legacyFareSelect)
              .eq('status', 'completed')
              .order('created_at', ascending: false);
        }
      }
    }

    if (response.isEmpty) {
      try {
        response = await supabase
            .from('trips')
            .select(modernCalculatedFareSelect)
            .order('created_at', ascending: false);
      } catch (_) {
        try {
          response = await supabase
              .from('trips')
              .select(legacyCalculatedFareSelect)
              .order('created_at', ascending: false);
        } catch (_) {
          try {
            response = await supabase
                .from('trips')
                .select(modernFareSelect)
                .order('created_at', ascending: false);
          } catch (_) {
            try {
              response = await supabase
                  .from('trips')
                  .select(legacyFareSelect)
                  .order('created_at', ascending: false);
            } catch (_) {
              return [];
            }
          }
        }
      }
    }

    return response.cast<Map<String, dynamic>>().where((trip) {
      final tripPlate = _normalizePlate(
        trip['plate_number'] ?? trip['driver_plate'],
      );
      return tripPlate.isNotEmpty && tripPlate == normalizedPlate;
    }).toList();
  }

  double _resolveTripFare(Map<String, dynamic> trip) {
    final raw = trip['fare'] ?? trip['calculated_fare'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String _tripUuid(Map<String, dynamic> trip) {
    final uuid = (trip['uuid'] ?? trip['trip_uuid'] ?? trip['id'] ?? '')
        .toString();
    return uuid.toLowerCase() == 'null' ? '' : uuid;
  }

  Future<void> _loadTrips() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      await SyncService().syncOnStart().timeout(
        const Duration(seconds: 12),
        onTimeout: () {},
      );

      final driverId = supabase.auth.currentUser?.id;
      if (driverId == null || driverId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allDriverTrips = [];
          _filteredTrips = [];
          _totalEarnings = 0.0;
          _completedTrips = 0;
          _averageFare = 0.0;
        });
        return;
      }

      final driverPlate = await _resolveDriverPlate(driverId);
      final normalizedDriverPlate = _normalizePlate(driverPlate);

      final cloudRows = await _fetchCloudTripsByPlate(
        normalizedDriverPlate,
      ).timeout(const Duration(seconds: 10), onTimeout: () => []);

      if (cloudRows.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _allDriverTrips = cloudRows;
        });

        _applyFilter(_activeFilter, keepCalendarDate: true);
        return;
      }

      final db = await _localDb.database;
      final allTrips = await db.query('trips', orderBy: 'date DESC');

      final rows = allTrips.where((trip) {
        final sameDriverId = (trip['driver_id'] ?? '').toString() == driverId;

        if (sameDriverId) return true;

        if (normalizedDriverPlate.isEmpty) return false;

        final tripPlate = _normalizePlate(trip['plate_number']);
        return tripPlate.isNotEmpty && tripPlate == normalizedDriverPlate;
      }).toList();

      if (!mounted) return;
      setState(() {
        _allDriverTrips = rows;
      });

      _applyFilter(_activeFilter, keepCalendarDate: true);
    } catch (e) {
      debugPrint('Driver earnings load error: $e');
      if (!mounted) return;
      setState(() {
        _allDriverTrips = [];
        _filteredTrips = [];
        _totalEarnings = 0.0;
        _completedTrips = 0;
        _averageFare = 0.0;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    EarningsFilter filter, {
    DateTime? calendarDate,
    bool keepCalendarDate = false,
  }) {
    final now = DateTime.now();
    final selectedDate = keepCalendarDate
        ? _selectedCalendarDate
        : (calendarDate ?? _selectedCalendarDate);

    DateTime targetDate;
    if (filter == EarningsFilter.today) {
      targetDate = DateTime(now.year, now.month, now.day);
    } else if (filter == EarningsFilter.yesterday) {
      final y = now.subtract(const Duration(days: 1));
      targetDate = DateTime(y.year, y.month, y.day);
    } else {
      targetDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    }

    final filtered = _allDriverTrips.where((trip) {
      final tripDate = _resolveTripDate(trip);
      if (tripDate == null) return false;
      return DateUtils.isSameDay(tripDate, targetDate);
    }).toList();

    double total = 0.0;

    for (final trip in filtered) {
      final fare = _resolveTripFare(trip);
      total += fare;
    }

    final tripCount = filtered.length;

    setState(() {
      _activeFilter = filter;
      if (filter == EarningsFilter.calendar) {
        _selectedCalendarDate = targetDate;
      }
      _filteredTrips = filtered;
      _totalEarnings = total;
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
    _applyFilter(EarningsFilter.calendar, calendarDate: picked);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                  children: [
                    const Text(
                      'DRIVER EARNINGS',
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
                    _buildEarningsScoreCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCards(),
                    const SizedBox(height: 18),
                    Text(
                      _activeFilter == EarningsFilter.calendar
                          ? 'Trips on ${DateFormat('MMM dd, yyyy').format(_selectedCalendarDate)}'
                          : 'Trip Earnings',
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
                          'No trip earnings for this filter yet.',
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

  Widget _buildFilterRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _filterButton(
                label: 'Today',
                selected: _activeFilter == EarningsFilter.today,
                onTap: () => _applyFilter(EarningsFilter.today),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterButton(
                label: 'Yesterday',
                selected: _activeFilter == EarningsFilter.yesterday,
                onTap: () => _applyFilter(EarningsFilter.yesterday),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _filterButton(
                label: 'Calendar',
                selected: _activeFilter == EarningsFilter.calendar,
                onTap: () async {
                  await _pickCalendarDate();
                },
              ),
            ),
          ],
        ),
        if (_activeFilter == EarningsFilter.calendar) ...[
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

  Widget _buildEarningsScoreCard() {
    final bool isToday = _activeFilter == EarningsFilter.today;
    final double target = isToday ? 1000.0 : 800.0;
    final int score = ((_totalEarnings / target) * 100).clamp(0, 100).round();
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
                  'Earning Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PHP ${_totalEarnings.toStringAsFixed(0)} earned',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Target: PHP ${target.toStringAsFixed(0)}',
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
          label: 'Earnings',
          value: 'PHP ${_totalEarnings.toStringAsFixed(0)}',
          valueColor: Colors.blueAccent,
        ),
        const SizedBox(width: 10),
        _summaryItem(
          label: 'Trips',
          value: '$_completedTrips',
          valueColor: Colors.orangeAccent,
        ),
        const SizedBox(width: 10),
        _summaryItem(
          label: 'Avg Fare',
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
    final tripUuid = _tripUuid(trip);

    String when = 'Unknown date';
    final date = _resolveTripDate(trip);
    if (date != null) {
      when = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    }

    final pickup = (trip['pickup'] ?? 'Unknown').toString();
    final dropOff = (trip['drop_off'] ?? 'Unknown').toString();

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
            ),
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
                '₱${fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
        ),
        if (tripUuid.isNotEmpty)
          FutureBuilder<bool>(
            future: LocalDatabase().isTripReported(tripUuid),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IgnorePointer(
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.6),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'REPORTED',
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}
