import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constant/app_colors.dart';
import 'widgets/report_status_hero.dart';
import 'widgets/report_detail_row.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailsScreen({super.key, required this.report});

  static const Color backgroundColor = Color(0xFFF8F9FB);
  static const Color accentRed = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReportStatusHero(report: report, accentRed: accentRed),
                      const SizedBox(height: 24),
                      _buildSectionLabel("INCIDENT INFORMATION"),
                      _buildInfoCard(context),
                      const SizedBox(height: 24),
                      _buildSectionLabel("ISSUE DESCRIPTION"),
                      _buildNarrativeCard(),
                      if (report['evidence_url']?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 24),
                        _buildSectionLabel("ATTACHED EVIDENCE"),
                        _buildEvidenceGallery(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accentRed.withOpacity(0.12), backgroundColor],
            stops: const [0.0, 0.4],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.darkNavy,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "CASE #${report['id'] ?? '---'}",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: AppColors.darkNavy,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          ReportDetailRow(
            icon: Icons.badge_outlined,
            label: "Driver ID",
            value: report['driver_id'] ?? "N/A",
          ),
          _buildDivider(),
          ReportDetailRow(
            icon: Icons.numbers_rounded,
            label: "Trip Reference",
            value: report['trip_uuid'] ?? "N/A",
            isCopyable: true,
            iconColor: accentRed,
          ),
          _buildDivider(),
          ReportDetailRow(
            icon: Icons.calendar_today_rounded,
            label: "Reported On",
            value: _formatFullDate(report['reported_at']),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Text(
        report['description'] ?? "No details provided.",
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.darkNavy.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEvidenceGallery() {
    final String path = report['evidence_url'];
    final bool isLocal = !path.startsWith('http');
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: isLocal
              ? FileImage(File(path))
              : NetworkImage(path) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.fullscreen_rounded, color: accentRed),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: accentRed.withOpacity(0.8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.black.withOpacity(0.05)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x05000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildDivider() => Divider(
    height: 1,
    color: Colors.grey.withOpacity(0.1),
    indent: 16,
    endIndent: 16,
  );

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return dateStr ?? "N/A";
    }
  }
}
