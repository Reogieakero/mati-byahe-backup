import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import 'widgets/home_header.dart';
import 'widgets/dashboard_cards.dart';
import 'widgets/verification_overlay.dart';
import 'widgets/location_selector.dart';
import 'widgets/action_grid_widget.dart';
import 'widgets/active_trip_widget.dart';
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

  Map<String, dynamic>? _activeTripData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final verified = await _controller.checkVerification(widget.email);
    final activeData = await _controller.loadSavedFare(widget.email);

    if (mounted) {
      setState(() {
        _isVerified = verified;
        _activeTripData = activeData;
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                DashboardCards(
                  tripCount: 0,
                  driverName: widget.role.toLowerCase() == 'driver'
                      ? "You"
                      : "Plan your ride...",
                  plateNumber: "--- ---",
                  email: widget.email,
                  role: widget.role,
                ),
                const ActionGridWidget(),
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
      ],
    );
  }

  Widget _buildActiveTrip() {
    final fareValue = (_activeTripData?['fare'] as num?)?.toDouble() ?? 0.0;

    return ActiveTripWidget(
      fare: fareValue,
      onArrived: () {
        _controller.confirmArrival(context, () async {
          // 1. Capture the data we need before we nullify the state
          final dataToClear = _activeTripData;

          // 2. TARGET THE WIDGET: Update state immediately to swap the view
          if (mounted) {
            setState(() {
              _activeTripData = null;
            });
          }

          // 3. Background database cleanup (Home Screen is already refreshed)
          if (dataToClear != null) {
            await _controller.clearFare(
              email: widget.email,
              pickup: dataToClear['pickup'] ?? "Unknown",
              dropOff: dataToClear['drop_off'] ?? "Unknown",
              gasTier: dataToClear['gas_tier'] ?? "N/A",
              fare: fareValue,
              startTime: dataToClear['start_time'],
              driverName: "None Assigned",
              driverPlate: dataToClear['driver_plate'] ?? "---",
              driverId: null,
              onCleared: () {
                // Background sync happens here
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
            driverPlate: dataToClear?['driver_plate'] ?? "---",
            driverId: null,
            onCleared: () {},
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
        });
      },
      onFareCalculated: (fare) {},
    );
  }
}
