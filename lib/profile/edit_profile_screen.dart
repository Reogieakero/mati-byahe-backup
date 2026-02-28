import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';

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
  final LocalDatabase _localDb = LocalDatabase();
  final SyncService _syncService = SyncService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  final List<String> _suffixes = ['', 'Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];
  String _selectedSuffix = '';

  @override
  void initState() {
    super.initState();

    List<String> parts = widget.initialName.trim().split(' ');
    String first = '';
    String last = '';
    String middle = '';
    String foundSuffix = '';

    if (parts.isNotEmpty) {
      for (var s in _suffixes) {
        if (s.isNotEmpty && parts.last.toLowerCase() == s.toLowerCase()) {
          foundSuffix = s;
          parts.removeLast();
          break;
        }
      }

      first = parts[0];
      if (parts.length > 1) {
        last = parts.last;
        if (parts.length > 2) {
          middle = parts.sublist(1, parts.length - 1).join(' ');
        }
      }
    }

    _firstNameController = TextEditingController(text: first);
    _middleNameController = TextEditingController(text: middle);
    _lastNameController = TextEditingController(text: last);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _selectedSuffix = foundSuffix;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final String fullName = [
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _lastNameController.text.trim(),
      _selectedSuffix,
    ].where((s) => s.isNotEmpty).join(' ');

    final String phone = _phoneController.text.trim();
    final String? userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;

    await _localDb.updateUserProfile(id: userId, name: fullName, phone: phone);
    _syncService.syncOnStart();

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildSectionLabel("NAME DETAILS"),
              _buildInputField(
                label: "First Name",
                controller: _firstNameController,
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: "Middle Name",
                controller: _middleNameController,
                icon: Icons.person_pin_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildInputField(
                      label: "Last Name",
                      controller: _lastNameController,
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: _buildSuffixDropdown()),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionLabel("CONTACT INFORMATION"),
              _buildInputField(
                label: "Email Address",
                controller: _emailController,
                icon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: "Phone Number",
                controller: _phoneController,
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
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

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textGrey.withOpacity(0.7),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSuffixDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suffix",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSuffix,
          isExpanded: true,
          items: _suffixes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value.isEmpty ? 'None' : value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (newValue) => setState(() => _selectedSuffix = newValue!),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.more_horiz_rounded,
              size: 16,
              color: AppColors.primaryBlue,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.darkNavy : AppColors.textGrey,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.primaryBlue),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
