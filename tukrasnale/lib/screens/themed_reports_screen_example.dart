import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/image_upload_widget.dart';
import '../services/image_upload_service.dart';
import '../models/report_models.dart';

class ThemedReportsScreen extends StatefulWidget {
  const ThemedReportsScreen({super.key});

  @override
  State<ThemedReportsScreen> createState() => _ThemedReportsScreenState();
}

class _ThemedReportsScreenState extends State<ThemedReportsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  ReportType _selectedType = ReportType.krasnalMissing;
  String? _photoUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const ThemedAppBar(
          title: 'Reports',
          showLogo: true,
        ),
        body: Column(
          children: [
            // Themed Tab Bar
            Container(
              color: TuKrasnaleColors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: TuKrasnaleColors.brickRed,
                unselectedLabelColor: TuKrasnaleColors.textSecondary,
                indicatorColor: TuKrasnaleColors.brickRed,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Submit Report', icon: Icon(Icons.report)),
                  Tab(text: 'My Reports', icon: Icon(Icons.history)),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: Container(
                color: TuKrasnaleColors.background,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSubmitReportTab(),
                    _buildMyReportsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Submit a Report',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve the app by reporting issues or missing krasnale.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Report Type Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<ReportType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'What would you like to report?',
                  ),
                  items: ReportType.values.map((type) {
                    return DropdownMenuItem<ReportType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _getReportTypeIcon(type),
                            color: TuKrasnaleColors.brickRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(_getReportTypeLabel(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (ReportType? newType) {
                    setState(() {
                      _selectedType = newType!;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Report Details Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Brief title for your report',
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Please describe the issue in detail',
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (Optional)',
                    hintText: 'Where is this issue located?',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Photo Upload Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo Evidence',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Adding a photo helps us understand the issue better.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                
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
          
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: TuKrasnaleButton(
              text: _isSubmitting ? 'Submitting...' : 'Submit Report',
              onPressed: _isSubmitting ? null : _submitReport,
              icon: Icons.send,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Guidelines Card
          TuKrasnaleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: TuKrasnaleColors.skyBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reporting Guidelines',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Be specific and clear in your description\n'
                  '• Include location details when possible\n'
                  '• Attach photos for visual issues\n'
                  '• Reports are reviewed within 24-48 hours',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReportsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.history,
                color: TuKrasnaleColors.darkBrown,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Report History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sample Report Cards
          Expanded(
            child: ListView(
              children: [
                _buildReportCard(
                  'Missing Krasnal near Market',
                  'The krasnal that used to be near the market square seems to be missing.',
                  ReportStatus.pending,
                  DateTime.now().subtract(const Duration(hours: 2)),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  'Wrong Location Data',
                  'The GPS coordinates for "Happy Krasnal" seem to be incorrect.',
                  ReportStatus.inReview,
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  'App Crash on Discovery',
                  'App crashes when I try to mark a krasnal as discovered.',
                  ReportStatus.resolved,
                  DateTime.now().subtract(const Duration(days: 3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, ReportStatus status, DateTime submittedAt) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
      case ReportStatus.inReview:
        statusColor = TuKrasnaleColors.skyBlue;
        statusIcon = Icons.rate_review;
        statusText = 'In Review';
        break;
      case ReportStatus.resolved:
        statusColor = TuKrasnaleColors.forestGreen;
        statusIcon = Icons.check_circle;
        statusText = 'Resolved';
        break;
      case ReportStatus.rejected:
        statusColor = TuKrasnaleColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
    }

    return TuKrasnaleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Submitted ${_formatDate(submittedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _getReportTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.krasnalMissing:
        return Icons.location_off;
      case ReportType.wrongLocation:
        return Icons.wrong_location;
      case ReportType.inappropriateContent:
        return Icons.report_problem;
      case ReportType.technicalIssue:
        return Icons.bug_report;
      case ReportType.other:
        return Icons.help_outline;
    }
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.krasnalMissing:
        return 'Missing Krasnal';
      case ReportType.wrongLocation:
        return 'Wrong Location';
      case ReportType.inappropriateContent:
        return 'Inappropriate Content';
      case ReportType.technicalIssue:
        return 'Technical Issue';
      case ReportType.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  void _submitReport() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the title and description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    
    // Simulate report submission
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form and switch to history tab
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _photoUrl = null;
          _selectedType = ReportType.krasnalMissing;
        });
        
        _tabController.animateTo(1);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}