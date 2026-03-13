import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import 'widgets/home_header.dart';
import 'widgets/dashboard_cards.dart';
import 'widgets/verification_overlay.dart';
import 'widgets/location_selector.dart';
import 'widgets/action_grid_widget.dart';
import 'widgets/active_trip_widget.dart';
import '../core/database/sync_service.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String role;
  const HomeScreen({super.key, required this.email, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final HomeController _controller = HomeController();
  bool _isVerified = false;
  bool _isLoading = true;
  bool _isSendingCode = false;

  int _todayTripCount = 0;
  int _driverPassengerCount = 0;
  String _latestPlate = "None";

  Map<String, dynamic>? _activeTripData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _refreshStats() async {
    final stats = await _controller.getDashboardStats(
      email: widget.email,
      role: widget.role,
    );
    if (mounted) {
      setState(() {
        _todayTripCount = stats['count'];
        _latestPlate = stats['plate'];
        _driverPassengerCount = stats['passengers'] ?? 0;
      });
    }
  }

  Future<void> _initialize() async {
    await SyncService().syncOnStart();

    final verified = await _controller.checkVerification(widget.email);
    final activeData = await _controller.loadSavedFare(widget.email);

    if (mounted) {
      setState(() {
        _isVerified = verified;
        _activeTripData = activeData;
        _isLoading = false;
      });

      await _refreshStats();

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.darkNavy,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: !_isVerified ? _buildRestrictedView() : _buildHomeContent(),
      ),
    );
  }

  Widget _buildRestrictedView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 60,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Access Restricted",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 32),
            VerificationOverlay(
              isSendingCode: _isSendingCode,
              onVerify: () => _controller.handleVerification(
                context: context,
                email: widget.email,
                setSendingState: (s) => setState(() => _isSendingCode = s),
                onReturn: _initialize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        const HomeHeader(),
        Expanded(
          // ADDED: RefreshIndicator provides the pull-to-refresh behavior
          child: RefreshIndicator(
            color: AppColors.darkNavy,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await _initialize();
            },
            child: SingleChildScrollView(
              // Physics MUST be set to AlwaysScrollableScrollPhysics for the
              // RefreshIndicator to work even if the content is short.
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  DashboardCards(
                    tripCount: _todayTripCount,
                    passengerCount: _driverPassengerCount,
                    plateNumber: _latestPlate,
                    email: widget.email,
                    role: widget.role,
                  ),
                  ActionGridWidget(role: widget.role),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _activeTripData != null
                        ? _buildActiveTrip()
                        : _buildLocationSelector(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTrip() {
    final fareValue = (_activeTripData?['fare'] as num?)?.toDouble() ?? 0.0;

    return ActiveTripWidget(
      fare: fareValue,
      onArrived: () {
        _controller.confirmArrival(context, () async {
          final dataToClear = _activeTripData;

          if (mounted) {
            setState(() {
              _activeTripData = null;
            });
          }

          if (dataToClear != null) {
            await _controller.clearFare(
              email: widget.email,
              pickup: dataToClear['pickup'] ?? "Unknown",
              dropOff: dataToClear['drop_off'] ?? "Unknown",
              gasTier: dataToClear['gas_tier'] ?? "N/A",
              fare: fareValue,
              startTime: dataToClear['start_time'],
              driverName: "None Assigned",
              driverPlate: dataToClear['plate_number'] ?? "---",
              driverId: null,
              onCleared: () {
                _refreshStats();
              },
            );
          }
        });
      },

      onCancel: () {
        _controller.confirmChangeRoute(context, () async {
          final dataToClear = _activeTripData;
          if (mounted) {
            setState(() {
              _activeTripData = null;
            });
          }
          // Background cleanup
          await _controller.clearFare(
            email: widget.email,
            pickup: "Cancelled",
            dropOff: "Cancelled",
            gasTier: "N/A",
            fare: 0.0,
            startTime: _activeTripData?['start_time'],
            driverName: "Cancelled",
            driverPlate: dataToClear?['plate_number'] ?? "---",
            driverId: null,
            onCleared: () {
              _refreshStats();
            },
          );
        });
      },
    );
  }

  Widget _buildLocationSelector() {
    return LocationSelector(
      email: widget.email,
      role: widget.role,
      onTripStarted: (data) {
        setState(() {
          _activeTripData = data;
          _latestPlate = data['plate_number'] ?? "---";
        });
      },
      onFareCalculated: (fare) {},
    );
  }
}
