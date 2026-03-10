import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constant/app_colors.dart';
import '../../core/database/local_database.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final supabase = Supabase.instance.client;
  final LocalDatabase _localDb = LocalDatabase();
  late Future<List<Map<String, dynamic>>> _localTripsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLocalData();
    _startBackgroundSync();
  }

  void _refreshLocalData() {
    final userId = supabase.auth.currentUser?.id ?? '';
    setState(() {
      _localTripsFuture = _localDb.getTripsByPassengerId(userId);
    });
  }

  void _startBackgroundSync() {
    supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) async {
            final db = await _localDb.database;
            final batch = db.batch();
            for (var trip in data) {
              batch.insert('trips', {
                'uuid': trip['uuid'] ?? trip['id'],
                'passenger_id': trip['passenger_id'],
                'driver_id': trip['driver_id'],
                'driver_name': trip['driver_name'],
                'driver_plate': trip['driver_plate'],
                'pickup': trip['pickup'],
                'drop_off': trip['drop_off'],
                'fare': (trip['calculated_fare'] as num?)?.toDouble() ?? 0.0,
                'gas_tier': trip['gas_tier'],
                'date': trip['created_at'],
                'start_time': trip['start_time'],
                'end_time': trip['end_time'],
                'is_synced': 1,
              }, conflictAlgorithm: ConflictAlgorithm.replace);
            }
            await batch.commit(noResult: true);
            _refreshLocalData();
          },
          onError: (err) {
            debugPrint("Stream error: $err");
          },
        );
  }

  Map<String, dynamic> _processTripData(List<Map<String, dynamic>> trips) {
    final now = DateTime.now();
    double today = 0, yesterday = 0, mondayTotal = 0;
    List<double> weekly = List.filled(7, 0.0);

    for (var trip in trips) {
      if (trip['date'] == null) continue;
      try {
        final date = DateTime.parse(trip['date']);
        final fare = (trip['fare'] as num?)?.toDouble() ?? 0.0;

        if (DateUtils.isSameDay(date, now)) today += fare;
        if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
          yesterday += fare;
        }

        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final tripDay = DateTime(date.year, date.month, date.day);
        final mondayDay = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );

        if (!tripDay.isBefore(mondayDay)) {
          if (date.weekday == 1) mondayTotal += fare;
          weekly[date.weekday - 1] += fare;
        }
      } catch (e) {
        continue;
      }
    }
    return {
      'today': today,
      'yesterday': yesterday,
      'monday': mondayTotal,
      'weeklyData': weekly,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _localTripsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenseTrips = snapshot.data ?? [];
          final stats = _processTripData(expenseTrips);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 50, 10, 15),
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: AppColors.darkNavy,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      'SPENDING',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkNavy,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _refreshLocalData();
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 10),
                      if (expenseTrips.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text("No expenses recorded yet."),
                          ),
                        )
                      else ...[
                        _buildProChart(stats['weeklyData']),
                        const SizedBox(height: 24),
                        _buildSummaryCards(
                          today: stats['today'],
                          yesterday: stats['yesterday'],
                          monday: stats['monday'],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "Expense History",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...expenseTrips.take(15).map((trip) => _tripTile(trip)),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProChart(List<double> weeklyData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 24, 20, 10),
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  const days = [
                    'MON',
                    'TUE',
                    'WED',
                    'THU',
                    'FRI',
                    'SAT',
                    'SUN',
                  ];
                  int index = value.toInt();
                  if (index >= 0 && index < days.length) {
                    return SideTitleWidget(
                      meta: meta,
                      space: 14,
                      child: Text(
                        days[index],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: weeklyData
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: Colors.blueAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.3),
                    Colors.blueAccent.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards({
    required double today,
    required double yesterday,
    required double monday,
  }) {
    return Row(
      children: [
        _summaryItem("Today", today, Colors.blueAccent),
        const SizedBox(width: 12),
        _summaryItem("Yesterday", yesterday, Colors.orangeAccent),
        const SizedBox(width: 12),
        _summaryItem("Monday", monday, Colors.greenAccent),
      ],
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
              "₱${amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripTile(Map<String, dynamic> trip) {
    String formattedDate = 'Unknown date';
    if (trip['date'] != null) {
      try {
        formattedDate = DateFormat(
          'MMM dd, hh:mm a',
        ).format(DateTime.parse(trip['date']));
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${trip['pickup']} → ${trip['drop_off']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "-₱${trip['fare']}",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
