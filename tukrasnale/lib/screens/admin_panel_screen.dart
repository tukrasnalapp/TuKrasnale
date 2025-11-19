import 'package:flutter/material.dart';
//import '../models/krasnal_models.dart';
import '../models/report_models.dart';
import '../services/admin_service.dart';
import '../screens/enhanced_add_krasnal_tab.dart';
import '../screens/manage_krasnale_tab.dart'; // Enhanced version with images

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tu Krasnale - Admin Panel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[700], // Same as edit krasnal screen
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.add_location), text: 'Add Krasnal'),
            Tab(icon: Icon(Icons.list), text: 'Manage Krasnale'),
            Tab(icon: Icon(Icons.report), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EnhancedAddKrasnalTab(),
          ManageKrasnaleTab(), // Enhanced version with images, view, and edit
          _ReportsTab(),
        ],
      ),
    );
  }
}

// Reports Management Tab
class _ReportsTab extends StatefulWidget {
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final AdminService _adminService = AdminService();
  List<KrasnaleReport> _reports = [];
  bool _isLoading = false;
  ReportStatus? _filterStatus;
  ReportType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _adminService.getAllReports();
      if (mounted) {
        setState(() {
          _reports = reports;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<KrasnaleReport> get _filteredReports {
    var filtered = _reports;

    if (_filterStatus != null) {
      filtered = filtered.where((r) => r.status == _filterStatus).toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((r) => r.reportType == _filterType).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _reports.where((r) => r.status == ReportStatus.pending).length;
    final inReviewCount = _reports.where((r) => r.status == ReportStatus.inReview).length;

    return Column(
      children: [
        // Stats and Filters
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats Row
              Row(
                children: [
                  _buildReportStatCard('Pending', pendingCount.toString(), Colors.orange),
                  const SizedBox(width: 8),
                  _buildReportStatCard('In Review', inReviewCount.toString(), Colors.blue),
                  const SizedBox(width: 8),
                  _buildReportStatCard('Total', _reports.length.toString(), Colors.grey),
                ],
              ),
              const SizedBox(height: 16),

              // Filters Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ReportStatus?>(
                      value: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Status',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<ReportStatus?>(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        ...ReportStatus.values.map((status) {
                          return DropdownMenuItem<ReportStatus?>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(_getStatusIcon(status), size: 16),
                                const SizedBox(width: 8),
                                Text(_getStatusText(status)),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<ReportType?>(
                      value: _filterType,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<ReportType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...ReportType.values.map((type) {
                          return DropdownMenuItem<ReportType?>(
                            value: type,
                            child: Text(_getReportTypeTitle(type)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterType = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _loadReports,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Reports List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredReports.isEmpty
                  ? _buildReportsEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = _filteredReports[index];
                        return _buildReportCard(report);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildReportStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus != null || _filterType != null
                ? 'No reports match your filters'
                : 'No reports yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(KrasnaleReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getStatusIcon(report.status),
                  color: _getStatusColor(report.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(report.status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Type and Date
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _getReportTypeTitle(report.reportType),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description Preview
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),

            // Admin Notes (if any)
            if (report.adminNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin: ${report.adminNotes}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _viewReportDetails(report),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                ),
                const SizedBox(width: 8),
                if (report.status == ReportStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () => _updateReportStatus(report, ReportStatus.inReview),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Review'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                const SizedBox(width: 8),
                if (report.status != ReportStatus.resolved)
                  ElevatedButton.icon(
                    onPressed: () => _resolveReport(report),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                const SizedBox(width: 8),
                if (report.status != ReportStatus.rejected)
                  ElevatedButton.icon(
                    onPressed: () => _rejectReport(report),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.missing:
        return 'Missing Krasnal';
      case ReportType.wrongLocation:
        return 'Wrong Location';
      case ReportType.wrongInfo:
        return 'Wrong Information';
      case ReportType.damaged:
        return 'Damaged';
      case ReportType.newSuggestion:
        return 'New Suggestion';
      case ReportType.other:
        return 'Other';
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inReview:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.schedule;
      case ReportStatus.inReview:
        return Icons.visibility;
      case ReportStatus.resolved:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inReview:
        return 'In Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  void _viewReportDetails(KrasnaleReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_getReportTypeTitle(report.reportType)),
              const SizedBox(height: 12),
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_getStatusText(report.status)),
              const SizedBox(height: 12),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(report.description),
              if (report.locationLat != null && report.locationLng != null) ...[
                const SizedBox(height: 12),
                const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${report.locationLat}, ${report.locationLng}'),
              ],
              if (report.adminNotes != null) ...[
                const SizedBox(height: 12),
                const Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(report.adminNotes!),
              ],
              const SizedBox(height: 12),
              const Text('Submitted:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _updateReportStatus(KrasnaleReport report, ReportStatus status) async {
    try {
      await _adminService.updateReportStatus(report.id, status);
      await _loadReports(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${_getStatusText(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resolveReport(KrasnaleReport report) {
    _showAdminNotesDialog(report, ReportStatus.resolved, 'Resolve Report');
  }

  void _rejectReport(KrasnaleReport report) {
    _showAdminNotesDialog(report, ReportStatus.rejected, 'Reject Report');
  }

  void _showAdminNotesDialog(KrasnaleReport report, ReportStatus newStatus, String title) {
    final notesController = TextEditingController(text: report.adminNotes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add admin notes for "${report.title}":'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.updateReportStatus(
                  report.id,
                  newStatus,
                  adminNotes: notesController.text,
                );
                await _loadReports(); // Refresh
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report ${_getStatusText(newStatus).toLowerCase()}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating report: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(newStatus == ReportStatus.resolved ? 'Resolve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}