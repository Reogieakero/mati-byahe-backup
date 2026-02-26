import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constant/app_colors.dart';
import '../components/confirmation_dialog.dart';
import 'widgets/reason_selector.dart';
import 'widgets/details_input.dart';
import 'widgets/other_reason_input.dart';
import 'widgets/submit_button.dart';
import 'widgets/media_proof.dart';
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

  void _showSuccessNotification(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 15,
        right: 15,
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
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Report Submitted",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Thank you for your feedback.",
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
        issueType: issueType,
        description: _detailsController.text,
        evidencePath: _proofFile?.path,
      );

      SyncService().syncOnStart();

      if (!mounted) return;

      _showSuccessNotification(context);
      Navigator.pop(context);
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
      extendBody: true,
      backgroundColor: Colors.white,
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
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReasonSelector(
                      selectedReason: _selectedReason,
                      reasons: _reasons,
                      onSelected: (val) =>
                          setState(() => _selectedReason = val),
                    ),
                    if (_selectedReason == "Other")
                      OtherReasonInput(controller: _otherReasonController),
                    MediaProof(
                      file: _proofFile,
                      onPickImage: () => _handleMediaPick(false),
                      onPickVideo: () => _handleMediaPick(true),
                      onRemove: () => setState(() => _proofFile = null),
                    ),
                    const SizedBox(height: 24),
                    DetailsInput(controller: _detailsController),
                    const SizedBox(height: 32),
                    _isSubmitting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                            ),
                          )
                        : SubmitButton(onPressed: _handleSubmit),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        "REPORT TRIP",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: AppColors.darkNavy,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.darkNavy,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
