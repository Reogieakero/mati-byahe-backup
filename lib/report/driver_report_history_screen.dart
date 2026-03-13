import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import 'report_details_screen.dart';
import 'widgets/report_history_empty_state.dart';
import 'widgets/report_history_tile.dart';

class DriverReportHistoryScreen extends StatefulWidget {
  const DriverReportHistoryScreen({super.key});

  @override
  State<DriverReportHistoryScreen> createState() =>
      _DriverReportHistoryScreenState();
}

class _DriverReportHistoryScreenState extends State<DriverReportHistoryScreen> {
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;
  final SyncService _syncService = SyncService();

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = false;
  String _driverId = '';

  @override
  void initState() {
    super.initState();
    _refreshData();
    _triggerSync();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _loadHistory().then((list) {
      if (!mounted) return;
      setState(() {
        _allReports = list;
        _filteredReports = List.from(list);
        _isLoading = false;
      });
    });
  }

  Future<void> _triggerSync() async {
    await _syncService.syncOnStart();
    _refreshData();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    _driverId = user.id;
    return _localDb.getReportsForDriver(user.id);
  }

  void _filterReports(String query) {
    final searchLower = query.toLowerCase();
    setState(() {
      _filteredReports = _allReports.where((report) {
        final pickup = (report['pickup'] ?? '').toString().toLowerCase();
        final dropOff = (report['drop_off'] ?? '').toString().toLowerCase();
        final issueType = (report['issue_type'] ?? '').toString().toLowerCase();
        return pickup.contains(searchLower) ||
            dropOff.contains(searchLower) ||
            issueType.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopBar(),
          _buildInfoBanner(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : (_filteredReports.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _triggerSync,
                          color: Colors.black,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.62,
                                child: const ReportHistoryEmptyState(),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _triggerSync,
                          color: Colors.black,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100, top: 8),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = _filteredReports[index];
                              return ReportHistoryTile(
                                report: report,
                                onViewDetails: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReportDetailsScreen(report: report),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 50, 10, 15),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Text(
            'REPORT HISTORY',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE3A3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _driverId.isEmpty
                  ? 'Reports will appear here when a report matches your driver profile.'
                  : 'Matched reports for driver: ${_allReports.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterReports,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search issue or location...',
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 15, right: 10),
            child: Icon(Icons.search, size: 20, color: Colors.black54),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _filterReports('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
