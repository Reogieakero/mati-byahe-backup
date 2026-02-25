import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import '../signup/verification_screen.dart';
import 'widgets/home_header.dart';
import 'widgets/dashboard_cards.dart';
import 'widgets/verification_overlay.dart';
import 'widgets/location_selector.dart';
import 'widgets/action_grid_widget.dart';
import 'widgets/fare_display.dart';
import 'widgets/confirmation_dialog.dart';
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
  final LocalDatabase _localDb = LocalDatabase();
  bool _isVerified = false;
  bool _isLoading = true;
  bool _isSendingCode = false;
  double? _persistedFare;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadStatus();
    await _loadSavedFare();
  }

  Future<void> _loadStatus() async {
    final verified = await _controller.checkVerification(widget.email);
    if (mounted) {
      setState(() {
        _isVerified = verified;
        _isLoading = false;
      });
    }
    SyncService().syncOnStart();
  }

  Future<void> _loadSavedFare() async {
    final fare = await _localDb.getActiveFare(widget.email);
    if (mounted && fare != null) {
      setState(() {
        _persistedFare = fare;
      });
    }
  }

  Future<void> _handleFareUpdate(double fare) async {
    setState(() => _persistedFare = fare);
    await _localDb.saveActiveFare(widget.email, fare);
    _showTripStartNotification();
  }

  void _showTripStartNotification() {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
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
                              "Your active trip is now being tracked.",
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

  Future<void> _clearFare() async {
    setState(() => _persistedFare = null);
    await _localDb.clearActiveFare(widget.email);
  }

  Future<void> _handleVerification() async {
    setState(() => _isSendingCode = true);
    try {
      await _controller.resendVerificationCode(widget.email);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(email: widget.email),
        ),
      ).then((_) => _loadStatus());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error")));
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  void _confirmArrival() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "End Trip?",
        content: "Are you sure you have reached your destination?",
        confirmText: "Yes, Arrived",
        onConfirm: _clearFare,
      ),
    );
  }

  void _confirmChangeRoute() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Change Route?",
        content: "This will cancel your current fare calculation. Continue?",
        confirmText: "Change",
        onConfirm: _clearFare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Container(
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
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
              onVerify: _handleVerification,
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
                  tripCount: 4,
                  driverName: widget.role.toLowerCase() == 'driver'
                      ? "You"
                      : "Lito Lapid",
                  plateNumber: "CLB 4930",
                  email: widget.email,
                  role: widget.role,
                ),
                const ActionGridWidget(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _persistedFare != null
                      ? _buildActiveTripView()
                      : LocationSelector(
                          email: widget.email,
                          onFareCalculated: _handleFareUpdate,
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTripView() {
    return Card(
      elevation: 8,
      shadowColor: AppColors.primaryBlue.withOpacity(0.2),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "ACTIVE TRIP",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.primaryBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _confirmChangeRoute,
                  icon: const Icon(
                    Icons.edit_location_alt_outlined,
                    color: Colors.grey,
                    size: 22,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            FareDisplay(fare: _persistedFare!, onArrived: _confirmArrival),
          ],
        ),
      ),
    );
  }
}
