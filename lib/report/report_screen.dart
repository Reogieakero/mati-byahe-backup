import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constant/app_colors.dart';
import '../components/confirmation_dialog.dart';
import 'widgets/reported/reason_selector.dart';
import 'widgets/reported/details_input.dart';
import 'widgets/reported/other_reason_input.dart';
import 'widgets/reported/submit_button.dart';
import 'widgets/reported/media_proof.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';

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

      await _localDb.saveReport(
        tripUuid: widget.trip['uuid'],
        passengerId: widget.trip['passenger_id'].toString(),
        driverId: widget.trip['driver_id'].toString(),
        issueType: issueType,
        description: _detailsController.text,
        evidencePath: _proofFile?.path,
      );

      await SyncService().syncOnStart();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.black),
      );
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
