import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../components/confirmation_dialog.dart';
import 'edit_profile_controller.dart';
import 'widgets/profile_form_fields.dart';
import 'widgets/suffix_dropdown.dart';
import 'qr_code_screen.dart';
import '../core/widgets/sileo_notification.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String role;

  const EditProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.role,
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
        title: "Update Profile",
        content: "Are you sure you want to save these changes?",
        confirmText: "Save",
        onConfirm: () async {
          Navigator.pop(context);
          setState(() => _controller.isLoading = true);

          final success = await _controller.saveProfile();

          if (mounted) {
            setState(() => _controller.isLoading = false);

            if (success) {
              SileoNotification.show(
                context,
                'Profile saved successfully!',
                type: SileoNoticeType.success,
                duration: const Duration(seconds: 2),
              );

              if (widget.role.toLowerCase() == 'driver') {
                final userId = _controller.getUserId();
                if (userId != null) {
                  final localData = await LocalDatabase().getUserById(userId);
                  if (mounted && localData != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            QRCodeScreen(driverData: localData),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(context, true);
              }
            } else {
              SileoNotification.show(
                context,
                'Error saving profile. Please try again.',
                type: SileoNoticeType.error,
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    final bool isDriver = widget.role.toLowerCase() == 'driver';

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
              Center(
                child: GestureDetector(
                  onTap: () async {
                    await _controller.pickImage();
                    setState(() {});
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: _controller.selectedImage != null
                            ? FileImage(_controller.selectedImage!)
                            : (_controller.currentAvatarUrl != null
                                      ? NetworkImage(
                                          _controller.currentAvatarUrl!,
                                        )
                                      : null)
                                  as ImageProvider?,
                        child:
                            _controller.selectedImage == null &&
                                _controller.currentAvatarUrl == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const ProfileSectionLabel("NAME DETAILS"),
              ProfileTextField(
                label: "First Name",
                controller: _controller.firstNameController,
                icon: Icons.person_outline_rounded,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              ProfileTextField(
                label: "Middle Name",
                controller: _controller.middleNameController,
                icon: Icons.person_pin_outlined,
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
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SuffixDropdown(
                      value: _controller.selectedSuffix,
                      items: _controller.suffixes,
                      onChanged: (val) =>
                          setState(() => _controller.selectedSuffix = val!),
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
                validator: (v) => v!.length < 10 ? "Invalid phone" : null,
              ),
              if (isDriver) ...[
                const SizedBox(height: 32),
                const ProfileSectionLabel("DRIVER & VEHICLE DETAILS"),
                ProfileTextField(
                  label: "License Number",
                  controller: _controller.licenseNumberController,
                  icon: Icons.contact_emergency_outlined,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                ProfileTextField(
                  label: "Home Address",
                  controller: _controller.addressController,
                  icon: Icons.home_outlined,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ProfileTextField(
                        label: "Plate Number",
                        controller: _controller.plateNumberController,
                        icon: Icons.numbers_rounded,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProfileTextField(
                        label: "Vehicle Type",
                        controller: _controller.vehicleTypeController,
                        icon: Icons.directions_car_filled_outlined,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ProfileTextField(
                  label: "Vehicle Color",
                  controller: _controller.vehicleColorController,
                  icon: Icons.color_lens_outlined,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _controller.isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _controller.isLoading ? "SAVING..." : "SAVE CHANGES",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
