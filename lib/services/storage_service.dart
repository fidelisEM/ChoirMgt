import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class StorageService {
  factory StorageService() => _instance;
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  bool _storageInitialized = false;

  /// Initialize storage buckets required by the application
  Future<bool> initializeStorage() async {
    if (_storageInitialized) return true;

    Logger.info('StorageService: Initializing storage buckets...');

    try {
      // Check if we're authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        Logger.warning('StorageService: No authenticated user for storage initialization');
        return false;
      }

      // Get current user role to check permissions
      final userRole = await _getCurrentUserRole();
      Logger.debug('StorageService: Current user role: $userRole');

      // List of required buckets
      final requiredBuckets = [
        {
          'name': 'choir-images',
          'public': true,
          'allowedMimeTypes': ['image/jpeg', 'image/png', 'image/webp']
        },
        {
          'name': 'avatars',
          'public': true,
          'allowedMimeTypes': ['image/jpeg', 'image/png', 'image/webp']
        },
      ];

      bool allBucketsReady = true;

      for (final bucketConfig in requiredBuckets) {
        final bucketName = bucketConfig['name'] as String;
        final success = await _ensureBucketExists(bucketConfig);

        if (!success) {
          Logger.warning('StorageService: Failed to ensure bucket exists: $bucketName');
          allBucketsReady = false;
        }
      }

      if (allBucketsReady) {
        _storageInitialized = true;
        Logger.info('StorageService: Storage initialization completed successfully');
        return true;
      } else {
        Logger.warning('StorageService: Storage initialization completed with some failures');
        return false;
      }
    } catch (e) {
      Logger.error('StorageService: Error during storage initialization', e);
      return false;
    }
  }

  /// Ensure a specific bucket exists, create if not
  Future<bool> _ensureBucketExists(Map<String, dynamic> bucketConfig) async {
    final bucketName = bucketConfig['name'] as String;

    try {
      // First, try to list existing buckets
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == bucketName);

      if (bucketExists) {
        Logger.debug('StorageService: Bucket "$bucketName" already exists');
        return true;
      }

      Logger.debug('StorageService: Creating bucket "$bucketName"...');

      // Attempt 1: Try creating with current user permissions
      try {
        await _createBucketWithOptions(bucketConfig);
        Logger.info('StorageService: Successfully created bucket "$bucketName"');
        return true;
      } catch (createError) {
        Logger.error('StorageService: Failed to create bucket "$bucketName"', createError);

        // Attempt 2: Try with service role if available
        return await _createBucketWithServiceRole(bucketConfig);
      }
    } catch (e) {
      Logger.error('StorageService: Error ensuring bucket "$bucketName"', e);
      return false;
    }
  }

  /// Create bucket with current user permissions
  Future<void> _createBucketWithOptions(Map<String, dynamic> config) async {
    final bucketName = config['name'] as String;
    final isPublic = config['public'] as bool;
    final allowedMimeTypes = List<String>.from(config['allowedMimeTypes']);

    await _supabase.storage.createBucket(
      bucketName,
      BucketOptions(
        public: isPublic,
        allowedMimeTypes: allowedMimeTypes,
      ),
    );
  }

  /// Alternative approach: Create bucket using service role
  Future<bool> _createBucketWithServiceRole(Map<String, dynamic> config) async {
    Logger.debug('StorageService: Attempting bucket creation with service role...');

    try {
      // This approach uses the service role key if available in environment
      // You would need to add your service role key to the config

      // For now, we'll create a policy-compliant request
      await _createBucketViaAPI(config);
      return true;
    } catch (e) {
      Logger.error('StorageService: Service role bucket creation failed', e);
      return false;
    }
  }

  /// Create bucket via direct API call
  Future<void> _createBucketViaAPI(Map<String, dynamic> config) async {
    // Use direct HTTP API call for bucket creation
    // This is a fallback approach - in practice you might need to implement
    // a server-side endpoint or use a service account
    throw Exception('Direct API bucket creation not implemented - requires service role');
  }

  /// Get current user role from the database
  Future<String> _getCurrentUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'anonymous';

      // Check if user has admin role
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] ?? 'user';
    } catch (e) {
      Logger.error('StorageService: Error getting user role', e);
      return 'user';
    }
  }

  /// Check if storage is properly initialized
  bool get isStorageReady => _storageInitialized;

  /// Force re-initialization of storage
  Future<bool> reinitializeStorage() async {
    _storageInitialized = false;
    return await initializeStorage();
  }

  /// Get storage initialization status
  Map<String, dynamic> getStorageStatus() {
    return {
      'initialized': _storageInitialized,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
