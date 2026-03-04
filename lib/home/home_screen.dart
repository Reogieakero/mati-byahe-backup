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
        if (activeData != null) {
          _activeTripData = activeData;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            const Icon(
              Icons.lock_person_rounded,
              size: 80,
              color: AppColors.primaryYellow,
            ),
            const SizedBox(height: 24),
            const Text(
              "Access Restricted",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                DashboardCards(
                  tripCount: 0,
                  driverName: widget.role.toLowerCase() == 'driver'
                      ? "You"
                      : "Searching...",
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
      onArrived: () => _controller.confirmArrival(context, () {
        _controller.clearFare(
          email: widget.email,
          pickup: _activeTripData?['pickup'] ?? "Unknown",
          dropOff: _activeTripData?['drop_off'] ?? "Unknown",
          gasTier: _activeTripData?['gas_tier'] ?? "N/A",
          fare: fareValue,
          startTime: _activeTripData?['start_time'],
          driverName: "None Assigned",
          driverId: null,
          onCleared: () => setState(() => _activeTripData = null),
        );
      }),
      onCancel: () => _controller.confirmChangeRoute(context, () {
        _controller.clearFare(
          email: widget.email,
          pickup: "Cancelled",
          dropOff: "Cancelled",
          gasTier: "N/A",
          fare: 0.0,
          startTime: _activeTripData?['start_time'],
          driverName: "Cancelled",
          driverId: null,
          onCleared: () => setState(() => _activeTripData = null),
        );
      }),
    );
  }

  Widget _buildLocationSelector() {
    return LocationSelector(
      email: widget.email,
      role: widget.role,
      onFareCalculated: (fare) async {
        final updatedData = await _controller.loadSavedFare(widget.email);
        setState(() {
          _activeTripData = updatedData;
        });
      },
    );
  }
}
