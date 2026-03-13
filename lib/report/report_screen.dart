import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constant/app_colors.dart';
import '../components/confirmation_dialog.dart';
import 'widgets/reported/reason_selector.dart';
import 'widgets/reported/details_input.dart';
import 'widgets/reported/other_reason_input.dart';
import 'widgets/reported/submit_button.dart';
import 'widgets/reported/media_proof.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import '../core/widgets/sileo_notification.dart';

class ReportScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const ReportScreen({super.key, required this.trip});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _otherReasonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;
  String? _selectedReason;
  File? _proofFile;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    "Incorrect Fare",
    "Driver Behavior",
    "Vehicle Issue",
    "Route Issue",
    "Smoking",
    "Uncomfortable Ride",
    "Other",
  ];

  String _asCleanString(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }

  Future<String> _resolveDriverIdFromTrip() async {
    final directDriverId = _asCleanString(widget.trip['driver_id']);
    if (directDriverId.isNotEmpty) {
      return directDriverId;
    }

    final plateNumber = _asCleanString(widget.trip['plate_number']);
    if (plateNumber.isEmpty) {
      return '';
    }

    final db = await _localDb.database;
    final localDriver = await db.query(
      'users',
      columns: ['id'],
      where: 'plate_number = ?',
      whereArgs: [plateNumber],
      limit: 1,
    );
    if (localDriver.isNotEmpty) {
      return _asCleanString(localDriver.first['id']);
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('plate_number', plateNumber)
          .maybeSingle();
      return _asCleanString(profile?['id']);
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleMediaPick(bool isVideo) async {
    final XFile? pickedFile = isVideo
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 70,
          );

    if (pickedFile != null) {
      setState(() {
        _proofFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _executeSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final String issueType = _selectedReason == "Other"
          ? _otherReasonController.text
          : _selectedReason!;
      final currentUser = _supabase.auth.currentUser;
      final tripUuid = _asCleanString(
        widget.trip['uuid'] ?? widget.trip['trip_uuid'] ?? widget.trip['id'],
      );
      final passengerId = _asCleanString(
        widget.trip['passenger_id'] ?? currentUser?.id,
      );
      final driverId = await _resolveDriverIdFromTrip();

      if (tripUuid.isEmpty || passengerId.isEmpty || driverId.isEmpty) {
        throw Exception(
          'Missing trip reference. Unable to submit this report because trip_uuid, passenger_id, or driver_id is empty.',
        );
      }

      final String reportedAt = DateTime.now().toIso8601String();
      final payload = {
        'trip_uuid': tripUuid,
        'passenger_id': passengerId,
        'driver_id': driverId,
        'issue_type': issueType,
        'description': _detailsController.text,
        'evidence_url': _proofFile?.path,
        'status': 'pending',
        'reported_at': reportedAt,
      };

      var synced = false;
      try {
        await _supabase
            .from('reports')
            .upsert(payload, onConflict: 'trip_uuid');
        synced = true;
      } catch (e) {
        debugPrint('Direct report insert failed: $e');
      }

      await _localDb.saveReport(
        tripUuid: tripUuid,
        passengerId: passengerId,
        driverId: driverId,
        issueType: issueType,
        description: _detailsController.text,
        evidencePath: _proofFile?.path,
        status: 'pending',
        reportedAt: reportedAt,
        isSynced: synced ? 1 : 0,
      );

      if (!synced) {
        await SyncService().syncOnStart();
      }

      if (!mounted) return;

      if (!synced) {
        SileoNotification.show(
          context,
          'Report saved locally and will sync when available.',
          type: SileoNoticeType.info,
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      SileoNotification.show(context, 'Error: $e', type: SileoNoticeType.error);
    }
  }

  void _handleSubmit() {
    if (_selectedReason == null || _isSubmitting) return;

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Submit Report",
        content: "Are you sure you want to submit this report?",
        confirmText: "Submit Report",
        onConfirm: _executeSubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              ReasonSelector(
                selectedReason: _selectedReason,
                reasons: _reasons,
                onSelected: (val) => setState(() => _selectedReason = val),
              ),
              if (_selectedReason == "Other") ...[
                const SizedBox(height: 12),
                OtherReasonInput(controller: _otherReasonController),
              ],
              const SizedBox(height: 20),
              MediaProof(
                file: _proofFile,
                onPickImage: () => _handleMediaPick(false),
                onPickVideo: () => _handleMediaPick(true),
                onRemove: () => setState(() => _proofFile = null),
              ),
              const SizedBox(height: 20),
              DetailsInput(controller: _detailsController),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
        child: _isSubmitting
            ? const SizedBox(
                height: 50,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.darkNavy),
                ),
              )
            : SubmitButton(onPressed: _handleSubmit),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Report an Issue",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Tell us what went wrong with your trip.",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.darkNavy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.trip['uuid']?.toString().substring(0, 8).toUpperCase() ??
              "REPORT",
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
