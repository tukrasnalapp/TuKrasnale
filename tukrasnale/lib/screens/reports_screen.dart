import 'package:flutter/material.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/image_upload_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  ReportType _reportType = ReportType.other;
  String? _krasnalId;
  double? _locationLat;
  double? _locationLng;
  String? _photoUrl;
  bool _isSubmitting = false;
  List<KrasnaleReport> _myReports = [];
  bool _isLoadingReports = false;

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Issues'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.report), text: 'New Report'),
              Tab(icon: Icon(Icons.history), text: 'My Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNewReportTab(),
            _buildMyReportsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report an Issue',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us improve the app by reporting issues with Krasnale locations, information, or suggesting new ones.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...ReportType.values.map((type) {
                      return RadioListTile<ReportType>(
                        title: Text(_getReportTypeTitle(type)),
                        subtitle: Text(_getReportTypeDescription(type)),
                        value: type,
                        groupValue: _reportType,
                        onChanged: (value) {
                          setState(() {
                            _reportType = value!;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                        hintText: 'Brief description of the issue',
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Title is required';
                        }
                        return null;
                      },
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                        hintText: 'Detailed description of the issue',
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Description is required';
                        }
                        return null;
                      },
                      onSaved: (value) => _description = value!,
                    ),
                    const SizedBox(height: 16),

                    // Location section (if needed)
                    if (_reportType == ReportType.newSuggestion || 
                        _reportType == ReportType.wrongLocation) ...[
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) {
                                if (value?.isNotEmpty ?? false) {
                                  _locationLat = double.tryParse(value!);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) {
                                if (value?.isNotEmpty ?? false) {
                                  _locationLng = double.tryParse(value!);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickLocationFromMap,
                        icon: const Icon(Icons.map),
                        label: const Text('Pick from Map'),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Photo upload
                    ImageUploadWidget(
                      initialImageUrl: _photoUrl,
                      uploadType: ImageUploadType.reportPhoto,
                      onImageSelected: (url) => setState(() => _photoUrl = url),
                      title: 'Photo (Optional)',
                      width: 200,
                      height: 150,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReportsTab() {
    if (_isLoadingReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myReports.isEmpty) {
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
              'No reports yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your submitted reports will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myReports.length,
      itemBuilder: (context, index) {
        final report = _myReports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(report.status),
              child: Icon(
                _getStatusIcon(report.status),
                color: Colors.white,
              ),
            ),
            title: Text(report.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getReportTypeTitle(report.reportType)),
                const SizedBox(height: 4),
                Text(
                  'Status: ${_getStatusText(report.status)}',
                  style: TextStyle(
                    color: _getStatusColor(report.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Submitted: ${_formatDate(report.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _showReportDetails(report),
          ),
        );
      },
    );
  }

  void _loadMyReports() async {
    setState(() {
      _isLoadingReports = true;
    });

    try {
      final reports = await _reportService.getUserReports();
      setState(() {
        _myReports = reports;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reports: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingReports = false;
      });
    }
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.missing:
        return 'Krasnal Missing';
      case ReportType.wrongLocation:
        return 'Wrong Location';
      case ReportType.wrongInfo:
        return 'Wrong Information';
      case ReportType.damaged:
        return 'Damaged Krasnal';
      case ReportType.newSuggestion:
        return 'New Krasnal Suggestion';
      case ReportType.other:
        return 'Other Issue';
    }
  }

  String _getReportTypeDescription(ReportType type) {
    switch (type) {
      case ReportType.missing:
        return 'A krasnal that should be there is missing';
      case ReportType.wrongLocation:
        return 'The location shown in the app is incorrect';
      case ReportType.wrongInfo:
        return 'The name, description, or other info is wrong';
      case ReportType.damaged:
        return 'The krasnal is damaged or vandalized';
      case ReportType.newSuggestion:
        return 'Suggest a new krasnal to add to the app';
      case ReportType.other:
        return 'Other issues not covered above';
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
        return 'Pending Review';
      case ReportStatus.inReview:
        return 'In Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _pickLocationFromMap() {
    // TODO: Implement map picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map picker coming soon!')),
    );
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isSubmitting = true;
      });

      try {
        await _reportService.submitReport(
          title: _title,
          description: _description,
          reportType: _reportType,
          krasnalId: _krasnalId,
          locationLat: _locationLat,
          locationLng: _locationLng,
          photoUrl: _photoUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
          _loadMyReports(); // Refresh the reports list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _title = '';
      _description = '';
      _reportType = ReportType.other;
      _krasnalId = null;
      _locationLat = null;
      _locationLng = null;
      _photoUrl = null;
    });
  }

  void _showReportDetails(KrasnaleReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${_getReportTypeTitle(report.reportType)}'),
              const SizedBox(height: 8),
              Text('Status: ${_getStatusText(report.status)}'),
              const SizedBox(height: 8),
              Text('Submitted: ${_formatDate(report.createdAt)}'),
              const SizedBox(height: 16),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(report.description),
              if (report.adminNotes != null) ...[
                const SizedBox(height: 16),
                const Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(report.adminNotes!),
              ],
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
}