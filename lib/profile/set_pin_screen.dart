import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import '../components/confirmation_dialog.dart';
import '../core/widgets/sileo_notification.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _supabase = Supabase.instance.client;
  final _localDb = LocalDatabase();
  final _syncService = SyncService();

  String _inputPin = "";
  String _storedPin = "";
  String _firstNewPin = ""; // Holds the first entry of the new PIN

  bool _isVerifyingExisting = false;
  bool _hasVerifiedOld = false;
  bool _isConfirmingNew = false; // True when user is re-entering the new PIN
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final localData = await _localDb.getUserById(user.id);
    _storedPin = localData?['login_pin'] ?? "";

    if (_storedPin.isEmpty) {
      final cloudData = await _supabase
          .from('profiles')
          .select('login_pin')
          .eq('id', user.id)
          .maybeSingle();
      _storedPin = cloudData?['login_pin'] ?? "";
      if (_storedPin.isNotEmpty)
        await _localDb.updateLocalPin(user.id, _storedPin);
    }

    setState(() {
      _isVerifyingExisting = _storedPin.isNotEmpty;
      _isLoading = false;
    });
  }

  void _onKeyTap(String value) {
    if (_inputPin.length < 4 && !_isSaving) {
      setState(() => _inputPin += value);
      if (_inputPin.length == 4) _handleStepCompletion();
    }
  }

  void _handleStepCompletion() {
    if (_isVerifyingExisting && !_hasVerifiedOld) {
      // Step 1: Verify Old PIN
      if (_inputPin == _storedPin) {
        setState(() {
          _hasVerifiedOld = true;
          _inputPin = "";
        });
        _showNotification("Identity confirmed. Now enter your new PIN.");
      } else {
        _showNotification(
          "Incorrect current PIN. Please try again.",
          isError: true,
        );
        setState(() => _inputPin = "");
      }
    } else if (!_isConfirmingNew) {
      // Step 2: Enter New PIN for the first time
      setState(() {
        _firstNewPin = _inputPin;
        _inputPin = "";
        _isConfirmingNew = true;
      });
      _showNotification("Please re-enter your new PIN to confirm.");
    } else {
      // Step 3: Confirm New PIN
      if (_inputPin == _firstNewPin) {
        _showConfirmDialog();
      } else {
        _showNotification(
          "PINs do not match. Let's try creating a new one again.",
          isError: true,
        );
        setState(() {
          _inputPin = "";
          _firstNewPin = "";
          _isConfirmingNew = false;
        });
      }
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: "Change PIN",
        content: "Do you want to change your PIN to this new 4-digit code?",
        confirmText: "Change PIN",
        onConfirm: _finalizePinChange,
      ),
    ).then((_) => setState(() => _inputPin = ""));
  }

  Future<void> _finalizePinChange() async {
    setState(() => _isSaving = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _localDb.updateLocalPin(user.id, _inputPin);
      await _syncService.syncOnStart();
      if (mounted) {
        _showNotification("Success! Your new PIN is now active.");
        Navigator.pop(context);
      }
    } catch (e) {
      _showNotification(
        "Error saving PIN. Check your connection.",
        isError: true,
      );
      setState(() {
        _isSaving = false;
        _inputPin = "";
      });
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    SileoNotification.show(
      context,
      message,
      type: isError ? SileoNoticeType.error : SileoNoticeType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        title: const Text(
          "LOGIN PIN",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          _buildFriendlyHeader(),
          const SizedBox(height: 40),
          _buildVisualDots(),
          const Spacer(),
          _buildKeypad(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFriendlyHeader() {
    String heading = "Set a New PIN";
    String description = "Create a 4-digit code to keep your account safe.";
    IconData icon = Icons.lock_open_rounded;

    if (_isVerifyingExisting && !_hasVerifiedOld) {
      heading = "Verify It's You";
      description = "Please enter your current PIN to make changes.";
      icon = Icons.security_rounded;
    } else if (_isConfirmingNew) {
      heading = "Confirm New PIN";
      description = "Please enter the new code one more time.";
      icon = Icons.phonelink_lock_rounded;
    } else if (_hasVerifiedOld || !_isVerifyingExisting) {
      heading = "Choose New PIN";
      description = "Enter the new 4-digit code you want to use.";
      icon = Icons.published_with_changes;
    }

    return Column(
      children: [
        Icon(icon, size: 48, color: AppColors.primaryBlue),
        const SizedBox(height: 20),
        Text(
          heading,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blueGrey,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isTyped = index < _inputPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isTyped
                ? AppColors.primaryBlue
                : Colors.grey.withOpacity(0.2),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((n) => _buildKey(n)).toList(),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60),
            _buildKey('0'),
            SizedBox(
              width: 60,
              child: IconButton(
                onPressed: () {
                  if (_inputPin.isNotEmpty)
                    setState(
                      () => _inputPin = _inputPin.substring(
                        0,
                        _inputPin.length - 1,
                      ),
                    );
                },
                icon: const Icon(
                  Icons.backspace_outlined,
                  color: AppColors.darkNavy,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _onKeyTap(label),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
      ),
    );
  }
}
