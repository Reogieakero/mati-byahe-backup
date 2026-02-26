import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constant/app_colors.dart';
import 'widgets/reason_selector.dart';
import 'widgets/details_input.dart';
import 'widgets/other_reason_input.dart';
import 'widgets/submit_button.dart';
import 'widgets/image_proof.dart';

class ReportScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const ReportScreen({super.key, required this.trip});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _otherReasonController = TextEditingController();
  String? _selectedReason;
  File? _proofImage;

  final List<String> _reasons = [
    "Incorrect Fare",
    "Driver Behavior",
    "Vehicle Issue",
    "Route Issue",
    "Smoking",
    "Uncomfortable Ride",
    "Other",
  ];

  Future<void> _handleImagePick() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
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
                    ImageProof(
                      image: _proofImage,
                      onPickImage: _handleImagePick,
                      onRemoveImage: () => setState(() => _proofImage = null),
                    ),
                    const SizedBox(height: 24),
                    DetailsInput(controller: _detailsController),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SubmitButton(
        onPressed: () {
          if (_selectedReason == null) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Report submitted successfully."),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
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
