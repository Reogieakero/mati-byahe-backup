import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../components/confirmation_dialog.dart';
import 'edit_profile_controller.dart';
import 'widgets/profile_form_fields.dart';
import 'widgets/suffix_dropdown.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final EditProfileController _controller = EditProfileController();

  @override
  void initState() {
    super.initState();
    _controller.init(
      name: widget.initialName,
      email: widget.initialEmail,
      phone: widget.initialPhone,
      onLoaded: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Lock Profile",
        content:
            "Saving these changes will lock your name for the next 14 days. Proceed?",
        confirmText: "Change",
        onConfirm: () async {
          final success = await _controller.saveProfile();
          if (mounted) {
            if (success) {
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error saving profile.")),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkNavy,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "EDIT PROFILE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppColors.darkNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_controller.canEdit) _buildLockWarning(),
              const ProfileSectionLabel("NAME DETAILS"),
              ProfileTextField(
                label: "First Name",
                controller: _controller.firstNameController,
                icon: Icons.person_outline_rounded,
                enabled: _controller.canEdit,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              ProfileTextField(
                label: "Middle Name",
                controller: _controller.middleNameController,
                icon: Icons.person_pin_outlined,
                enabled: _controller.canEdit,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ProfileTextField(
                      label: "Last Name",
                      controller: _controller.lastNameController,
                      icon: Icons.badge_outlined,
                      enabled: _controller.canEdit,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SuffixDropdown(
                      value: _controller.selectedSuffix,
                      items: _controller.suffixes,
                      onChanged: _controller.canEdit
                          ? (val) => setState(
                              () => _controller.selectedSuffix = val!,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const ProfileSectionLabel("CONTACT INFORMATION"),
              ProfileTextField(
                label: "Email Address",
                controller: _controller.emailController,
                icon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              ProfileTextField(
                label: "Phone Number",
                controller: _controller.phoneController,
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                enabled: true,
                validator: (v) => v!.length < 10 ? "Invalid phone" : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _controller.canEdit ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "SAVE CHANGES",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Profile changes are locked for 14 days. Available in ${_controller.daysRemaining} days.",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.brown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
