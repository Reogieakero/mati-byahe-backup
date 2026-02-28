import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/database/local_database.dart';

class EditProfileController {
  final _supabase = Supabase.instance.client;
  final LocalDatabase _localDb = LocalDatabase();

  late final TextEditingController firstNameController;
  late final TextEditingController middleNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  final List<String> suffixes = ['', 'Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];
  String selectedSuffix = '';

  bool canEdit = true;
  int daysRemaining = 0;
  bool isLoading = true;

  Future<void> init({
    required String name,
    required String email,
    required String phone,
    required Function onLoaded,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId != null) {
      try {
        final userData = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        _parseName(userData['full_name'] ?? name);
        emailController = TextEditingController(
          text: userData['email'] ?? email,
        );
        phoneController = TextEditingController(
          text: userData['phone_number'] ?? phone,
        );

        if (userData['last_name_change'] != null) {
          DateTime lastUpdate = DateTime.parse(
            userData['last_name_change'],
          ).toUtc();
          DateTime now = DateTime.now().toUtc();
          final difference = now.difference(lastUpdate).inDays;
          if (difference < 14) {
            canEdit = false;
            daysRemaining = 14 - difference;
          }
        }
      } catch (e) {
        _parseName(name);
        emailController = TextEditingController(text: email);
        phoneController = TextEditingController(text: phone);
      }
    }

    isLoading = false;
    onLoaded();
  }

  void _parseName(String name) {
    List<String> parts = name.trim().split(' ');
    String first = '', last = '', middle = '', foundSuffix = '';

    if (parts.isNotEmpty) {
      for (var s in suffixes) {
        if (s.isNotEmpty && parts.last.toLowerCase() == s.toLowerCase()) {
          foundSuffix = s;
          parts.removeLast();
          break;
        }
      }

      if (parts.length == 1) {
        first = parts[0];
      } else if (parts.length == 2) {
        first = parts[0];
        last = parts[1];
      } else if (parts.length >= 3) {
        first = parts[0];
        last = parts.last;
        middle = parts.sublist(1, parts.length - 1).join(' ');
      }
    }

    firstNameController = TextEditingController(text: first);
    middleNameController = TextEditingController(text: middle);
    lastNameController = TextEditingController(text: last);
    selectedSuffix = foundSuffix;
  }

  Future<bool> saveProfile() async {
    final String fullNameString = [
      firstNameController.text.trim(),
      middleNameController.text.trim(),
      lastNameController.text.trim(),
      selectedSuffix,
    ].where((s) => s.isNotEmpty).join(' ');

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _supabase
          .from('profiles')
          .update({
            'full_name': fullNameString,
            'phone_number': phoneController.text.trim(),
            'last_name_change': nowIso,
            'updated_at': nowIso,
          })
          .eq('id', userId);

      await _localDb.updateUserProfile(
        id: userId,
        name: fullNameString,
        phone: phoneController.text.trim(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }
}
