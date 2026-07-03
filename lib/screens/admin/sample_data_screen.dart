import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/sample_data_service.dart';
import '../../theme/app_colors.dart';

class SampleDataScreen extends StatefulWidget {
  const SampleDataScreen({super.key});

  @override
  State<SampleDataScreen> createState() => _SampleDataScreenState();
}

class _SampleDataScreenState extends State<SampleDataScreen> {
  final SampleDataService _sampleDataService = SampleDataService();
  bool _isLoading = false;
  String _status = '';
  final List<String> _logs = [];

  Future<void> _generateSampleData() async {
    setState(() {
      _isLoading = true;
      _status = 'Generating sample data...';
      _logs.clear();
    });

    try {
      _addLog('🚀 Starting comprehensive sample data generation...');
      
      await _sampleDataService.generateAllSampleData();
      
      _addLog('✅ Sample data generation completed successfully!');
      _addLog('📊 Generated data includes:');
      _addLog('   • 13 sample users (admin, leaders, members)');
      _addLog('   • 5 diverse choirs with different characteristics');
      _addLog('   • 30+ choir memberships with realistic data');
      _addLog('   • Activity feed with recent actions');
      _addLog('   • Realistic attendance and payment records');
      
      setState(() {
        _status = 'Sample data generated successfully!';
        _isLoading = false;
      });

      Get.snackbar(
        'Success',
        'Sample data has been generated successfully. You can now explore the choir features!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

    } catch (e) {
      _addLog('❌ Error generating sample data: $e');
      setState(() {
        _status = 'Error generating sample data';
        _isLoading = false;
      });

      Get.snackbar(
        'Error',
        'Failed to generate sample data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _generateQuickData() async {
    setState(() {
      _isLoading = true;
      _status = 'Generating quick test data...';
      _logs.clear();
    });

    try {
      _addLog('🚀 Generating quick test data...');
      
      await _sampleDataService.generateQuickTestData();
      
      _addLog('✅ Quick test data generated successfully!');
      
      setState(() {
        _status = 'Quick test data generated!';
        _isLoading = false;
      });

      Get.snackbar(
        'Success',
        'Quick test data has been generated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );

    } catch (e) {
      _addLog('❌ Error generating quick data: $e');
      setState(() {
        _status = 'Error generating quick data';
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toLocal().toString().substring(11, 19)} - $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Data Generator'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generate Sample Data',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This will populate your database with realistic sample data to test all the choir management features.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        
                        // Full Sample Data Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _generateSampleData,
                            icon: _isLoading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.data_usage),
                            label: const Text('Generate Complete Sample Data'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Quick Test Data Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _generateQuickData,
                            icon: const Icon(Icons.flash_on),
                            label: const Text('Generate Quick Test Data'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Status
                        if (_status.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _status.contains('Error') 
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _status.contains('Error') 
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                            child: Text(
                              _status,
                              style: TextStyle(
                                color: _status.contains('Error') 
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sample Data Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What will be generated:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem('👥 Users', '13 realistic users (admin, choir leaders, members)'),
                        _buildFeatureItem('🎵 Choirs', '5 diverse choirs with different characteristics'),
                        _buildFeatureItem('👤 Memberships', '30+ choir memberships with realistic data'),
                        _buildFeatureItem('📊 Statistics', 'Attendance rates, payment records, and activity logs'),
                        _buildFeatureItem('🎯 Features', 'All updated features will work with real data'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Logs Section
                if (_logs.isNotEmpty)
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Generation Log:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    _logs.join('\n'),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}