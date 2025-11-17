import 'package:flutter/material.dart';
import '../services/admin_service_debug.dart';
import '../models/krasnal_models.dart';

class DebugAdminTestScreen extends StatefulWidget {
  const DebugAdminTestScreen({super.key});

  @override
  State<DebugAdminTestScreen> createState() => _DebugAdminTestScreenState();
}

class _DebugAdminTestScreenState extends State<DebugAdminTestScreen> {
  final AdminServiceDebug _debugService = AdminServiceDebug();
  String _debugOutput = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Debug Test'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Debug Admin Functionality',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Test Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testAdminStatus,
              child: Text(_isLoading ? 'Testing...' : 'Test Admin Status'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _makeUserAdmin,
              child: const Text('Make Current User Admin'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateKrasnal,
              child: const Text('Test Create Krasnal'),
            ),
            const SizedBox(height: 16),
            
            // Debug Output
            const Text(
              'Debug Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty ? 'No output yet. Click a button to test.' : _debugOutput,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _debugOutput = '';
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Clear Output'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testAdminStatus() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Testing admin status...\n\n';
    });

    try {
      final isAdmin = await _debugService.isCurrentUserAdminDebug();
      setState(() {
        _debugOutput += '\n--- ADMIN STATUS TEST COMPLETE ---\n';
        _debugOutput += 'Result: ${isAdmin ? "USER IS ADMIN" : "USER IS NOT ADMIN"}\n';
      });
    } catch (e) {
      setState(() {
        _debugOutput += '\n--- ERROR DURING ADMIN TEST ---\n';
        _debugOutput += 'Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _makeUserAdmin() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Setting current user as admin...\n\n';
    });

    try {
      final success = await _debugService.makeCurrentUserAdmin();
      setState(() {
        _debugOutput += '\n--- MAKE ADMIN COMPLETE ---\n';
        _debugOutput += 'Result: ${success ? "SUCCESS" : "FAILED"}\n';
      });
    } catch (e) {
      setState(() {
        _debugOutput += '\n--- ERROR DURING MAKE ADMIN ---\n';
        _debugOutput += 'Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateKrasnal() async {
    setState(() {
      _isLoading = true;
      _debugOutput = 'Testing krasnal creation...\n\n';
    });

    try {
      // Create test krasnal
      final testKrasnal = KrasnalModel(
        id: '',
        name: 'Debug Test Krasnal ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test krasnal created by the debug system',
        latitude: 51.1079,
        longitude: 17.0385,
        locationName: 'Debug Test Location',
        rarity: KrasnalRarity.common,
        pointsValue: 10,
        isActive: true,
        imageUrl: null,
        createdAt: DateTime.now(),
      );

      final success = await _debugService.createKrasnalDebug(testKrasnal);
      
      setState(() {
        _debugOutput += '\n--- CREATE KRASNAL TEST COMPLETE ---\n';
        _debugOutput += 'Result: ${success ? "SUCCESS - Krasnal created!" : "FAILED - Check logs above"}\n';
      });
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test krasnal created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _debugOutput += '\n--- ERROR DURING CREATE TEST ---\n';
        _debugOutput += 'Error: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}