import 'package:flutter/material.dart';
import '../../../report/report_screen.dart';
import '../../../core/database/local_database.dart';

class ReportButton extends StatelessWidget {
  final Map<String, dynamic> trip;

  const ReportButton({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LocalDatabase().isTripReported(trip['uuid']),
      builder: (context, snapshot) {
        final bool isReported = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
          child: OutlinedButton(
            onPressed: isReported ? null : () => _handleReportClick(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: isReported ? Colors.grey : Colors.redAccent,
              side: BorderSide(
                color: isReported
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.redAccent.withOpacity(0.5),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReported
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isReported ? "REPORT SUBMITTED" : "REPORT THIS TRIP",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleReportClick(BuildContext context) {
    _navigateToReport(context);
  }

  void _navigateToReport(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ReportScreen(trip: trip)));
  }
}
