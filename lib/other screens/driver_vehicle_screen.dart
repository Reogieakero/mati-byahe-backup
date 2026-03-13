import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';

class DriverVehicleScreen extends StatefulWidget {
  const DriverVehicleScreen({super.key});

  @override
  State<DriverVehicleScreen> createState() => _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends State<DriverVehicleScreen>
    with AutomaticKeepAliveClientMixin {
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  Map<String, dynamic> _driverData = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  String _safeText(dynamic value, String fallback) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }
    return text;
  }

  Future<void> _loadDriverData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      await SyncService().syncOnStart();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _driverData = {};
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> merged = {};

      final local = await _localDb.getUserById(user.id);
      if (local != null) {
        merged = Map<String, dynamic>.from(local);
      }

      try {
        final remote = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (remote != null) {
          merged = {...merged, ...remote};
        }
      } catch (_) {}

      merged['id'] = user.id;
      merged['email'] = merged['email'] ?? user.email ?? '';

      if (!mounted) return;
      setState(() {
        _driverData = merged;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _driverData = {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.darkNavy,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final qrPayload = {
      'driver_id': _safeText(_driverData['id'], 'N/A'),
      'full_name': _safeText(_driverData['full_name'], 'N/A'),
      'email': _safeText(_driverData['email'], 'N/A'),
      'phone_number': _safeText(_driverData['phone_number'], 'N/A'),
      'plate_number': _safeText(_driverData['plate_number'], 'N/A'),
      'vehicle_type': _safeText(_driverData['vehicle_type'], 'N/A'),
      'vehicle_color': _safeText(_driverData['vehicle_color'], 'N/A'),
      'license_number': _safeText(_driverData['license_number'], 'N/A'),
      'address': _safeText(_driverData['address'], 'N/A'),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 12, 15, 14),
              child: Text(
                'VEHICLE PROFILE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkNavy,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDriverData,
                color: AppColors.darkNavy,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 24),
                  children: [
                    _buildDriverIdentityCard(),
                    const SizedBox(height: 12),
                    _buildVehicleInfoCard(),
                    const SizedBox(height: 12),
                    _buildQrCard(jsonEncode(qrPayload)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _row('Driver Name', _safeText(_driverData['full_name'], 'Not set')),
          _divider(),
          _row('Driver ID', _safeText(_driverData['id'], 'Not set')),
          _divider(),
          _row('Email', _safeText(_driverData['email'], 'Not set')),
          _divider(),
          _row('Phone', _safeText(_driverData['phone_number'], 'Not set')),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _row(
            'Plate Number',
            _safeText(_driverData['plate_number'], 'Not set'),
          ),
          _divider(),
          _row(
            'Vehicle Type',
            _safeText(_driverData['vehicle_type'], 'Not set'),
          ),
          _divider(),
          _row(
            'Vehicle Color',
            _safeText(_driverData['vehicle_color'], 'Not set'),
          ),
          _divider(),
          _row(
            'License Number',
            _safeText(_driverData['license_number'], 'Not set'),
          ),
          _divider(),
          _row('Address', _safeText(_driverData['address'], 'Not set')),
        ],
      ),
    );
  }

  Widget _buildQrCard(String data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'DRIVER VEHICLE QR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.darkNavy,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.darkNavy,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan to view full driver and vehicle information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.darkNavy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.black.withOpacity(0.06)),
    );
  }
}
