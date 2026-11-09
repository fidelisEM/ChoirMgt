import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';

class StorageSetupScreen extends StatefulWidget {
  const StorageSetupScreen({super.key});

  @override
  State<StorageSetupScreen> createState() => _StorageSetupScreenState();
}

class _StorageSetupScreenState extends State<StorageSetupScreen> {
  bool _isLoading = false;
  String? _setupStatus;
  final List<String> _setupLogs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Setup'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatusSection(),
                const SizedBox(height: 16),
                _buildActionSection(),
                const SizedBox(height: 16),
                _buildLogsSection(),
                const SizedBox(height: 16),
                _buildManualInstructions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storage, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Storage Bucket Setup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Initialize storage buckets for image uploads',
            style: TextStyle(color: AppColors.gray600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          if (_setupStatus != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _setupStatus!.contains('Success')
                    ? Colors.green.withAlpha(30)
                    : Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _setupStatus!.contains('Success')
                        ? Icons.check_circle
                        : Icons.warning,
                    color: _setupStatus!.contains('Success')
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _setupStatus!,
                      style: TextStyle(
                        color: _setupStatus!.contains('Success')
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.help_outline, color: AppColors.gray600),
                  SizedBox(width: 8),
                  Text(
                    'Click "Initialize Storage" to check and setup buckets',
                    style: TextStyle(color: AppColors.gray600, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _initializeStorage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isLoading ? 'Initializing...' : 'Initialize Storage',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _checkStorageStatus,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Check Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    if (_setupLogs.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setup Logs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _setupLogs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _setupLogs[index],
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _setupLogs.clear();
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Logs'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInstructions() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Setup (If Automatic Fails)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If automatic setup fails, follow these steps:',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Go to your Supabase Dashboard\n'
                  '2. Navigate to Storage > Buckets\n'
                  '3. Click "New bucket"\n'
                  '4. Name: choir-images\n'
                  '5. Make it public: YES\n'
                  '6. Allowed MIME types: image/jpeg, image/png, image/webp',
                  style: TextStyle(color: AppColors.primary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text('SQL Alternative'),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SelectableText(
                  '''-- Create storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('choir-images', 'choir-images', true);

-- Set bucket permissions  
INSERT INTO storage.objects (bucket_id, name, owner, metadata)
VALUES ('choir-images', '.emptyFolderPlaceholder', NULL, '{}');

-- Enable RLS and create policies for uploads
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to upload
CREATE POLICY "Allow authenticated users to upload choir images" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'choir-images');

-- Allow public read access
CREATE POLICY "Allow public to view choir images" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'choir-images');''',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _initializeStorage() async {
    setState(() {
      _isLoading = true;
      _setupLogs.clear();
      _setupStatus = null;
    });

    try {
      _addLog('Starting storage initialization...');

      final storageService = StorageService();
      final success = await storageService.initializeStorage();

      if (success) {
        _addLog('✅ Storage initialization completed successfully');
        setState(() {
          _setupStatus = 'Success: Storage buckets are ready for use';
        });
        Helpers.showSuccessSnackbar('Storage initialized successfully!');
      } else {
        _addLog('❌ Storage initialization failed');
        setState(() {
          _setupStatus = 'Failed: Please check logs and try manual setup';
        });
        Helpers.showErrorSnackbar(
          'Storage initialization failed. Check logs for details.',
        );
      }
    } catch (e) {
      _addLog('❌ Error during initialization: $e');
      setState(() {
        _setupStatus = 'Error: $e';
      });
      Helpers.showErrorSnackbar('Storage initialization error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkStorageStatus() async {
    setState(() {
      _isLoading = true;
      _setupLogs.clear();
    });

    try {
      _addLog('Checking storage status...');

      final storageService = StorageService();
      final status = storageService.getStorageStatus();
      final isReady = storageService.isStorageReady;

      _addLog('Storage ready: $isReady');
      _addLog('Last check: ${status['timestamp']}');

      setState(() {
        _setupStatus = isReady
            ? 'Success: Storage is properly configured'
            : 'Pending: Storage needs initialization';
      });
    } catch (e) {
      _addLog('❌ Error checking status: $e');
      setState(() {
        _setupStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _setupLogs.add('[$timestamp] $message');
    });
  }
}
