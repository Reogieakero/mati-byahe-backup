import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constant/app_colors.dart';
import '../report/report_screen.dart';
import '../home/widgets/location_selector.dart';
import '../home/widgets/active_trip_widget.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import 'package:uuid/uuid.dart';

class DriverDetailsView extends StatefulWidget {
  final Map<String, dynamic> driverData;

  const DriverDetailsView({super.key, required this.driverData});

  @override
  State<DriverDetailsView> createState() => _DriverDetailsViewState();
}

class _DriverDetailsViewState extends State<DriverDetailsView> {
  final _supabase = Supabase.instance.client;
  final _localTripDb = LocalDatabase();
  final _syncService = SyncService();

  int _userRating = 0;
  String? _currentUserEmail;
  String? _currentUserId;
  String? _pickup;
  String? _dropOff;
  String _gasTier = 'Regular';
  bool _isArrived = false;
  bool _isTripActive = false;
  double _currentFare = 0.0;
  String? _activeTripId;

  @override
  void initState() {
    super.initState();
    _loadRealUser();
  }

  void _loadRealUser() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email;
        _currentUserId = user.id;
      });
    }
  }

  void _handleTripStarted(Map<String, dynamic> tripData) {
    setState(() {
      _pickup = tripData['pickup'] as String?;
      _dropOff = tripData['dropOff'] as String?;
      _gasTier = tripData['gasTier'] as String? ?? 'Regular';
    });
    final fare = tripData['fare'];
    if (fare is double) {
      _startTrip(fare);
    } else if (fare is int) {
      _startTrip(fare.toDouble());
    }
  }

  Future<void> _startTrip(double fare) async {
    // don't save trips without real pickup/dropoff
    if (_pickup == null || _dropOff == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select pickup and drop-off before starting trip.',
            ),
          ),
        );
      }
      return;
    }

    // generate our own uuid so we can reference the trip later
    final tripId = const Uuid().v4();

    await _localTripDb.saveTrip(
      uuid: tripId,
      email: _currentUserEmail ?? '',
      pickup: _pickup ?? 'Unknown',
      dropOff: _dropOff ?? '', // store destination immediately
      fare: fare,
      gasTier: _gasTier,
      passengerId: _currentUserId,
      driverId: widget.driverData['id']?.toString(),
      driverName: widget.driverData['name']?.toString(),
      driverPlate: widget.driverData['plate']?.toString(),
      startTime: DateTime.now().toIso8601String(),
    );
    await _syncService.syncOnStart();

    setState(() {
      _activeTripId = tripId;
      _currentFare = fare;
      _isTripActive = true;
    });
  }

  Future<void> _completeTrip() async {
    if (_activeTripId != null) {
      await _localTripDb.updateTripEnd(
        uuid: _activeTripId!,
        dropOff: _dropOff ?? '',
        endTime: DateTime.now().toIso8601String(),
      );
      await _syncService.syncOnStart();
    }

    setState(() {
      _isTripActive = false;
      _isArrived = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserEmail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "RIDE DETAILS",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppColors.darkNavy,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.report_gmailerrorred_rounded,
              color: Colors.redAccent,
            ),
            onPressed: () {
              final trip = {
                'uuid': widget.driverData['uuid'] ?? '',
                'passenger_id': _currentUserId ?? '',
                'driver_id': widget.driverData['id'] ?? '',
                'driver_plate': widget.driverData['plate'] ?? '',
                'driver_name': widget.driverData['name'] ?? '',
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportScreen(trip: trip),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFF0F2F5),
                    child: Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (widget.driverData['name'] ?? "UNKNOWN")
                        .toString()
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  Text(
                    "${widget.driverData['type']} • ${widget.driverData['plate']}",
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Plate: ${widget.driverData['plate'] ?? 'N/A'}",
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                    ),
                  ),
                  if (_isArrived) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      "RATE YOUR RIDE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() => _userRating = index + 1);
                          },
                          child: Icon(
                            index < _userRating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isArrived && !_isTripActive) ...[
                    const Text(
                      "SELECT DESTINATION",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textGrey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LocationSelector(
                      email: _currentUserEmail!,
                      role: "passenger",
                      onFareCalculated: (fare) => _startTrip(fare),
                      onTripStarted: _handleTripStarted,
                    ),
                  ],
                  if (_isTripActive)
                    ActiveTripWidget(
                      fare: _currentFare,
                      onArrived: _completeTrip,
                      onCancel: () {
                        setState(() {
                          _isTripActive = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
