import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/database/local_database.dart';
import '../core/database/sync_service.dart';
import '../core/services/report_service.dart';
import 'widgets/report_history_header.dart';
import 'widgets/report_history_tile.dart';
import 'widgets/report_history_empty_state.dart';
import '../components/confirmation_dialog.dart';
import 'report_details_screen.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final LocalDatabase _localDb = LocalDatabase();
  final _supabase = Supabase.instance.client;
  final SyncService _syncService = SyncService();
  final ReportService _reportService = ReportService();

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _triggerSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _refreshData() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    _loadHistory().then((list) {
      if (mounted) {
        setState(() {
          _allReports = list;
          _filteredReports = List.from(list);
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _triggerSync() async {
    await _syncService.syncOnStart();
    _refreshData();
  }

  Future<List<Map<String, dynamic>>> _loadHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    return await _localDb.getReportHistory(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            const ReportHistoryAppBar(),
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
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: const ReportHistoryEmptyState(),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _triggerSync,
                            color: Colors.black,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                bottom: 100,
                                top: 8,
                              ),
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
                                  onDelete: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogContext) =>
                                          ConfirmationDialog(
                                            title: "Unreport Trip",
                                            content:
                                                "Are you sure you want to unreport this trip? This will remove it from your visible history.",
                                            confirmText: "Unreport",
                                            onConfirm: () async {
                                              await _localDb.markAsUnreported(
                                                report['id'],
                                              );
                                              if (mounted) {
                                                _refreshData();
                                                _syncService.syncOnStart();
                                              }
                                            },
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
        onChanged: (q) => _filterReports(q),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Search location...",
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
                    _filterReports("");
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

  void _filterReports(String query) {
    setState(() {
      _filteredReports = _allReports.where((r) {
        final pickup = (r['pickup'] ?? "").toString().toLowerCase();
        final dropOff = (r['drop_off'] ?? "").toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return pickup.contains(searchLower) || dropOff.contains(searchLower);
      }).toList();
    });
  }
}
