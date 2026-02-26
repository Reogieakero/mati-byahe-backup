import 'package:flutter/material.dart';
import '../../../components/confirmation_dialog.dart';
import '../../report_screen.dart';

class ReportButton extends StatelessWidget {
  final Map<String, dynamic> trip;

  const ReportButton({super.key, required this.trip});

  void _navigateToReport(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReportScreen(trip: trip),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  void _handleReportClick(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Report Trip",
        content:
            "Are you sure you want to report this trip? This action will notify our support team to investigate the details.",
        confirmText: "Report",
        onConfirm: () async {
          _navigateToReport(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      color: Colors.transparent,
      child: OutlinedButton(
        onPressed: () => _handleReportClick(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          backgroundColor: Colors.transparent,
          elevation: 0,
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 18),
            SizedBox(width: 8),
            Text(
              "REPORT THIS TRIP",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
