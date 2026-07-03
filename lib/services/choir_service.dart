import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/logger.dart';

class ChoirService {
  factory ChoirService() => _instance;
  ChoirService._internal();
  static final ChoirService _instance = ChoirService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String> createChoir(ChoirModel choir) async {
    try {
      final response = await _supabase
          .from('choirs')
          .insert(choir.toJson())
          .select()
          .single();
      
      return response['id'];
    } catch (e) {
      Logger.error('Error creating choir: $e');
      rethrow;
    }
  }

  Future<ChoirModel?> getChoirById(String choirId) async {
    try {
      final response = await _supabase
          .from('choirs')
          .select()
          .eq('id', choirId)
          .single();
      
      return ChoirModel.fromJson(response);
    } catch (e) {
      Logger.error('Error getting choir: $e');
      return null;
    }
  }

  Future<List<ChoirModel>> getAllChoirs() async {
    try {
      final response = await _supabase
          .from('choirs')
          .select();
      
      return response.map<ChoirModel>((data) => ChoirModel.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error getting all choirs: $e');
      return [];
    }
  }

  Future<List<ChoirModel>> getChoirsByAdmin(String adminId) async {
    try {
      final response = await _supabase
          .from('choirs')
          .select()
          .eq('admin_id', adminId);
      
      return response.map<ChoirModel>((data) => ChoirModel.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error getting choirs by admin: $e');
      return [];
    }
  }

  Future<List<ChoirModel>> getChoirsByLeader(String leaderId) async {
    try {
      final response = await _supabase
          .from('choirs')
          .select()
          .eq('leader_id', leaderId);
      
      return response.map<ChoirModel>((data) => ChoirModel.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error getting choirs by leader: $e');
      return [];
    }
  }

  Future<List<ChoirModel>> searchChoirs(String query) async {
    try {
      final response = await _supabase
          .from('choirs')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%');
      
      return response.map<ChoirModel>((data) => ChoirModel.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error searching choirs: $e');
      return [];
    }
  }

  Future<String?> uploadChoirImageFromFile(String choirId, File imageFile) async {
    try {
      Logger.info('Starting image upload for choir: $choirId');
      final fileName = 'choir_${choirId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'choir-images/$fileName';
      
      // Read file as bytes for web compatibility
      final fileBytes = await imageFile.readAsBytes();
      Logger.debug('File size: ${fileBytes.length} bytes');
      
      // Check if bucket exists, create if it doesn't
      try {
        final buckets = await _supabase.storage.listBuckets();
        final bucketExists = buckets.any((bucket) => bucket.name == 'choir-images');
        
        if (!bucketExists) {
          Logger.info('Creating choir-images bucket...');
          await _supabase.storage.createBucket('choir-images', 
            const BucketOptions(public: true, allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp']));
          Logger.info('choir-images bucket created successfully');
        }
      } catch (bucketError) {
        Logger.warning('Bucket creation/check error: $bucketError');
      }
      
      Logger.debug('Uploading to path: $filePath');
      await _supabase.storage
          .from('choir-images')
          .uploadBinary(filePath, fileBytes, fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true, // Allow overwriting existing files
          ));
      
      final publicUrl = _supabase.storage
          .from('choir-images')
          .getPublicUrl(filePath);
      
      Logger.info('Upload successful. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      Logger.error('Error uploading choir image: $e');
      Logger.error('Error details: ${e.runtimeType}');
      if (e is StorageException) {
        Logger.error('Storage error: ${e.message}');
        Logger.error('Error code: ${e.statusCode}');
      }
      return null;
    }
  }

  Future<String?> uploadChoirImage(String choirId, XFile imageFile) async {
    try {
      Logger.info('Starting image upload for choir: $choirId');
      final fileName = 'choir_${choirId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'choir-images/$fileName';
      
      // Read file as bytes for web compatibility
      final fileBytes = await imageFile.readAsBytes();
      Logger.debug('File size: ${fileBytes.length} bytes');
      
      // Try uploading directly first (most efficient if bucket exists and is accessible)
      try {
        Logger.debug('Attempting direct upload to choir-images bucket...');
        await _supabase.storage
            .from('choir-images')
            .uploadBinary(filePath, fileBytes, fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ));
        
        final publicUrl = _supabase.storage
            .from('choir-images')
            .getPublicUrl(filePath);
        
        Logger.info('Direct upload successful. Public URL: $publicUrl');
        return publicUrl;
      } catch (uploadError) {
        Logger.warning('Direct upload failed: $uploadError');
        
        // Check if bucket exists and attempt to create if needed
        final bucketReady = await _ensureChoirImagesBucket();
        if (!bucketReady) {
          Logger.warning('Using placeholder image URL for now...');
          return 'https://via.placeholder.com/300x300.png?text=Upload+Failed';
        }
        
        // Retry upload after bucket verification/creation
        Logger.info('Retrying upload after bucket verification...');
      }
      
      Logger.debug('Uploading to path: $filePath');
      await _supabase.storage
          .from('choir-images')
          .uploadBinary(filePath, fileBytes, fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true, // Allow overwriting existing files
          ));
      
      final publicUrl = _supabase.storage
          .from('choir-images')
          .getPublicUrl(filePath);
      
      Logger.info('Upload successful. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      Logger.error('Error uploading choir image: $e');
      Logger.error('Error details: ${e.runtimeType}');
      if (e is StorageException) {
        Logger.error('Storage error: ${e.message}');
        Logger.error('Error code: ${e.statusCode}');
      }
      return null;
    }
  }

  Future<bool> updateChoir(ChoirModel choir) async {
    try {
      Logger.debug('Updating choir in database...');
      Logger.debug('Choir ID: ${choir.id}');
      Logger.debug('Choir name: ${choir.name}');
      Logger.debug('Image URL: ${choir.imageUrl}');
      
      final choirData = choir.toJson();
      Logger.debug('Update data: $choirData');
      Logger.debug('Name in JSON: ${choirData['name']}');
      
      await _supabase
          .from('choirs')
          .update(choirData)
          .eq('id', choir.id);
      
      Logger.info('Choir updated successfully in database');
      return true;
    } catch (e) {
      Logger.error('Error updating choir: $e');
      Logger.error('Error details: ${e.runtimeType}');
      if (e is PostgrestException) {
        Logger.error('Database error: ${e.message}');
        Logger.error('Error code: ${e.code}');
        Logger.error('Details: ${e.details}');
      }
      return false;
    }
  }

  Future<bool> deleteChoir(String choirId) async {
    try {
      await _supabase
          .from('choirs')
          .delete()
          .eq('id', choirId);
      
      return true;
    } catch (e) {
      Logger.error('Error deleting choir: $e');
      return false;
    }
  }

  Future<List<ChoirMemberModel>> getChoirMembers(String choirId) async {
    try {
      final response = await _supabase
          .from('choir_members')
          .select('''
            *,
            users!choir_members_user_id_fkey (
              id,
              full_name,
              email,
              phone_number
            )
          ''')
          .eq('choir_id', choirId);
      
      return response.map<ChoirMemberModel>((data) => ChoirMemberModel.fromJson(data)).toList();
    } catch (e) {
      Logger.error('Error getting choir members: $e');
      return [];
    }
  }

  Future<bool> addMemberToChoir(ChoirMemberModel member) async {
    try {
      await _supabase
          .from('choir_members')
          .insert(member.toJson());
      
      return true;
    } catch (e) {
      Logger.error('Error adding member to choir: $e');
      return false;
    }
  }

  Future<bool> removeMemberFromChoir(String memberId, String choirId) async {
    try {
      await _supabase
          .from('choir_members')
          .delete()
          .eq('id', memberId)
          .eq('choir_id', choirId);
      
      return true;
    } catch (e) {
      Logger.error('Error removing member from choir: $e');
      return false;
    }
  }

  /// Ensure the choir-images bucket exists, with multiple fallback strategies
  Future<bool> _ensureChoirImagesBucket() async {
    try {
      Logger.debug('Checking if choir-images bucket exists...');
      
      // Strategy 1: Try to access the bucket directly (faster and more reliable)
      try {
        // Attempt to list files in the bucket - if this succeeds, bucket exists
        await _supabase.storage.from('choir-images').list();
        Logger.info('choir-images bucket found and accessible');
        return true;
      } catch (accessError) {
        Logger.warning('Direct bucket access failed: $accessError');
        
        // Strategy 2: Check if bucket exists in list (fallback)
        try {
          final buckets = await _supabase.storage.listBuckets();
          final bucketExists = buckets.any((bucket) => bucket.name == 'choir-images');
          
          if (bucketExists) {
            Logger.warning('choir-images bucket found in list but may have access issues');
            return true; // Bucket exists but may have upload restrictions
          }
        } catch (listError) {
          Logger.error('Listing buckets failed: $listError');
        }
      }

      Logger.info('choir-images bucket does not exist, attempting to create...');

      // Strategy 2: Try to create bucket with current user
      try {
        await _supabase.storage.createBucket(
          'choir-images',
          const BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
          ),
        );
        Logger.info('Successfully created choir-images bucket');
        return true;
      } catch (createError) {
        Logger.warning('Failed to create bucket with current user: $createError');

        // Strategy 3: Try with admin privileges if current user is admin
        final isAdmin = await _checkIfCurrentUserIsAdmin();
        if (isAdmin) {
          return await _createBucketAsAdmin();
        }

        // Strategy 4: Guide user to create bucket manually
        Logger.error('MANUAL ACTION REQUIRED: Please ask a system administrator to create the storage bucket');
        Logger.info('Storage bucket setup steps:');
        Logger.info('1. Go to Supabase Dashboard > Storage > Buckets');
        Logger.info('2. Click "New bucket"');
        Logger.info('3. Name: choir-images');
        Logger.info('4. Make it public: YES');
        Logger.info('5. Allow file types: image/jpeg, image/png, image/webp');
        Logger.info('Or, run this SQL command in your Supabase SQL editor:');
        Logger.info('');
        Logger.info('-- Create storage bucket');
        Logger.info('INSERT INTO storage.buckets (id, name, public)');
        Logger.info("VALUES ('choir-images', 'choir-images', true);");
        Logger.info('');
        Logger.info('-- Set bucket permissions');
        Logger.info('INSERT INTO storage.objects (bucket_id, name, owner, metadata)');
        Logger.info("VALUES ('choir-images', '.emptyFolderPlaceholder', NULL, '{}');");
        
        return false;
      }
    } catch (e) {
      Logger.error('Error during bucket initialization: $e');
      return false;
    }
  }

  /// Check if current user has admin privileges
  Future<bool> _checkIfCurrentUserIsAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      
      final role = response['role'] as String?;
      return role == 'admin' || role == 'super_admin';
    } catch (e) {
      Logger.error('Error checking user admin status: $e');
      return false;
    }
  }

  /// Attempt to create bucket with admin privileges
  Future<bool> _createBucketAsAdmin() async {
    try {
      Logger.debug('Attempting bucket creation with admin privileges...');
      
      // Use admin client if available
      final adminClient = _supabase;
      
      await adminClient.storage.createBucket(
        'choir-images',
        const BucketOptions(
          public: true,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        ),
      );
      
      Logger.info('Successfully created bucket with admin privileges');
      return true;
    } catch (e) {
      Logger.error('Admin bucket creation failed: $e');
      return false;
    }
  }
}