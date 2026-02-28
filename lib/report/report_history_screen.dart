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

  Future<List<Map<String, dynamic>>>? _historyFuture;

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
      _historyFuture = _loadHistory();
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.redAccent.withOpacity(0.15),
              Colors.white,
              Colors.redAccent.withOpacity(0.05),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            const ReportHistoryAppBar(),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _triggerSync,
                      color: Colors.redAccent,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const ReportHistoryEmptyState(),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _triggerSync,
                    color: Colors.redAccent,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100, top: 8),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final report = snapshot.data![index];
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
                              builder: (dialogContext) => ConfirmationDialog(
                                title: "Unreport Trip",
                                content:
                                    "Are you sure you want to unreport this trip? This will remove it from your visible history.",
                                confirmText: "Unreport",
                                onConfirm: () async {
                                  await _localDb.markAsUnreported(report['id']);
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
