// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../core/constant/app_colors.dart';
// import '../core/services/auth_service.dart';
// import '../navigation/main_navigation.dart';

// class PinLoginScreen extends StatefulWidget {
//   final Map<String, dynamic> userData;
//   const PinLoginScreen({super.key, required this.userData});

//   @override
//   State<PinLoginScreen> createState() => _PinLoginScreenState();
// }

// class _PinLoginScreenState extends State<PinLoginScreen> {
//   final AuthService _authService = AuthService();
//   String _inputPin = "";
//   bool _isSyncing = false;

//   void _onKeyTap(String val) {
//     if (_inputPin.length < 4 && !_isSyncing) {
//       HapticFeedback.lightImpact();
//       setState(() => _inputPin += val);
//       if (_inputPin.length == 4) {
//         Future.delayed(const Duration(milliseconds: 200), _verifyAndSync);
//       }
//     }
//   }

//   Future<void> _verifyAndSync() async {
//     bool isValid = await _authService.verifyLocalPin(
//       widget.userData['id'],
//       _inputPin,
//     );

//     if (isValid) {
//       setState(() => _isSyncing = true);

//       await _authService.syncDownTransactions(widget.userData['id']);
//       await _authService.syncDownReports(widget.userData['id']);

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => MainNavigation(
//             email: widget.userData['email'],
//             role: widget.userData['role'],
//           ),
//         ),
//       );
//     } else {
//       _showError();
//     }
//   }

//   void _showError() {
//     HapticFeedback.vibrate();
//     setState(() => _inputPin = "");
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String name = widget.userData['full_name'] ?? 'User';

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 60),
//             CircleAvatar(
//               radius: 40,
//               backgroundColor: AppColors.primaryBlue,
//               child: Text(
//                 name[0].toUpperCase(),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 30,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "Welcome back, $name",
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),

//             _isSyncing
//                 ? Column(
//                     children: [
//                       const CircularProgressIndicator(),
//                       const SizedBox(height: 20),
//                       Text(
//                         "Syncing your data...",
//                         style: TextStyle(
//                           color: AppColors.primaryBlue,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   )
//                 : Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: List.generate(
//                       4,
//                       (i) => Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 10),
//                         width: 20,
//                         height: 20,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: i < _inputPin.length
//                               ? AppColors.primaryBlue
//                               : Colors.grey[200],
//                         ),
//                       ),
//                     ),
//                   ),

//             const Spacer(),
//             if (!_isSyncing) _buildNumpad(),
//             const SizedBox(height: 20),
//             TextButton(
//               onPressed: _isSyncing
//                   ? null
//                   : () async {
//                       await _authService.signOut();
//                       await _authService.clearLocalSession();
//                       if (!mounted) return;
//                       Navigator.pushNamedAndRemoveUntil(
//                         context,
//                         '/login',
//                         (route) => false,
//                       );
//                     },
//               child: const Text("SWITCH ACCOUNT"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNumpad() {
//     return GridView.count(
//       shrinkWrap: true,
//       crossAxisCount: 3,
//       padding: const EdgeInsets.symmetric(horizontal: 40),
//       children: [
//         ...["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"].map((
//           val,
//         ) {
//           if (val.isEmpty) return const SizedBox.shrink();
//           return InkWell(
//             onTap: () => val == "del"
//                 ? (_inputPin.isNotEmpty
//                       ? setState(
//                           () => _inputPin = _inputPin.substring(
//                             0,
//                             _inputPin.length - 1,
//                           ),
//                         )
//                       : null)
//                 : _onKeyTap(val),
//             child: Center(
//               child: Text(
//                 val,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           );
//         }),
//       ],
//     );
//   }
// }
