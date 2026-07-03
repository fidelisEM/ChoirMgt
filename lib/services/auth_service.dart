import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../utils/logger.dart';

class AuthService {
  factory AuthService() => _instance;
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  // Role from the `users` table, cached from the last successful
  // getCurrentUserProfile() call. Route/UI gating reads this instead of
  // Supabase auth user_metadata, which a signed-in user can edit themselves
  // via updateUser() - it must never be trusted for authorization. This
  // cache is a UX convenience only; the real authorization boundary is
  // Postgres RLS, which re-checks the DB role on every request regardless
  // of what the client believes it is.
  UserRole? _cachedRole;
  UserRole? get cachedRole => _cachedRole;

  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        Logger.debug('getCurrentUserProfile: No current user');
        return null;
      }

      final email = user.email;
      if (email == null) {
        Logger.warning('getCurrentUserProfile: User has no email');
        return null;
      }

      Logger.debug('getCurrentUserProfile: Fetching profile for user email: $email');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      Logger.debug('getCurrentUserProfile: Database response: $response');

      if (response == null) {
        Logger.info('getCurrentUserProfile: No profile found, creating default');
        // Create user profile if it doesn't exist
        final userModel = UserModel(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] ?? 'User',
          phoneNumber: user.userMetadata?['phone_number'] ?? '',
          role: UserRole.choirMember,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          suggestedChoir: user.userMetadata?['suggested_choir'] ?? '',
        );

        try {
          await _supabase
              .from('users')
              .upsert(userModel.toJson());
          _cachedRole = userModel.role;
          return userModel;
        } catch (e) {
          // If upsert fails, return a default profile
          Logger.warning('Failed to create profile, returning default: $e');
          _cachedRole = userModel.role;
          return userModel;
        }
      }

      final userModel = UserModel.fromJson({
        'id': response['id'],
        ...response,
      });

      Logger.debug('getCurrentUserProfile: Parsed user model - Name: ${userModel.fullName}, Role: ${userModel.role}');
      _cachedRole = userModel.role;
      return userModel;
    } catch (e) {
      Logger.error('Error getting user profile: $e');
      return null;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Attempting sign in with email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Logger.info('Sign in successful for user: ${response.user!.id}');
        await _updateLastLogin(response.user!.id);
        return await getCurrentUserProfile();
      }
      return null;
    } on AuthException catch (e) {
      Logger.error('Sign in AuthException: ${e.message}');
      Logger.error('Sign in StatusCode: ${e.statusCode}');
      throw _handleAuthException(e);
    } catch (e) {
      Logger.error('Sign in general error: $e');
      throw 'Sign in failed: $e';
    }
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    UserRole role = UserRole.choirMember,
    String suggestedChoir = '',
    String? profileImageUrl,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userModel = UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          suggestedChoir: suggestedChoir,
          profileImageUrl: profileImageUrl,
        );

        try {
          final userData = userModel.toJson();
          Logger.debug('Registering user data: $userData');
          await _supabase
              .from('users')
              .upsert(userData);
        } catch (e) {
          Logger.warning('Failed to create user profile during registration: $e');
          // Continue anyway, profile can be created later
        }

        return userModel;
      }
      return null;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _cachedRole = null;
    } catch (e) {
      Logger.error('Error signing out: $e');
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.choirmanagement://login-callback',
      );
      
      if (response) {
        await _updateLastLogin(_supabase.auth.currentUser!.id);
        return await getCurrentUserProfile();
      }
      return null;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google sign in failed: $e';
    }
  }

  Future<UserModel?> signInWithApple() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.example.choirmanagement://login-callback',
      );
      
      if (response) {
        await _updateLastLogin(_supabase.auth.currentUser!.id);
        return await getCurrentUserProfile();
      }
      return null;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Apple sign in failed: $e';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
    String? email,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        updates['full_name'] = displayName;
      }

      if (phoneNumber != null) {
        updates['phone_number'] = phoneNumber;
      }

      if (profileImageUrl != null) {
        updates['profile_image_url'] = profileImageUrl;
      }

      // Handle email update separately since it requires auth update
      if (email != null) {
        updates['email'] = email;
        // Update auth user email
        try {
          await _supabase.auth.updateUser(
            UserAttributes(email: email),
          );
        } catch (e) {
          throw 'Failed to update email in auth system: $e';
        }
      }

      if (updates.isNotEmpty) {
        final userEmail = user.email;
        if (userEmail == null) {
          throw Exception('User has no email address');
        }
        
        Logger.debug('updateProfile: Updating profile for user email: $userEmail');
        Logger.debug('updateProfile: Update data: $updates');
        
        // Update by email to match how getCurrentUserProfile works
        final result = await _supabase
            .from('users')
            .update(updates)
            .eq('email', userEmail)
            .select();
        
        Logger.debug('updateProfile: Update result: $result');
      }
    } catch (e) {
      Logger.error('Error updating profile: $e');
      rethrow;
    }
  }

  // Admin method to update any user's profile (for choir leaders/admins)
  Future<void> updateUserProfileByUserId({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final currentUserData = await getCurrentUserProfile();
      if (currentUserData?.role != UserRole.admin && 
          currentUserData?.role != UserRole.choirLeader) {
        throw Exception('Insufficient permissions to update user profiles');
      }

      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        updates['full_name'] = displayName;
      }

      if (phoneNumber != null) {
        updates['phone_number'] = phoneNumber;
      }

      if (email != null) {
        updates['email'] = email;
      }

      if (updates.isNotEmpty) {
        Logger.debug('updateUserProfileByUserId: Updating profile for user ID: $userId');
        Logger.debug('updateUserProfileByUserId: Update data: $updates');
        
        // Update by user ID
        final result = await _supabase
            .from('users')
            .update(updates)
            .eq('id', userId)
            .select();
        
        Logger.debug('updateUserProfileByUserId: Update result: $result');
      }
    } catch (e) {
      Logger.error('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<String?> uploadRegistrationImage(Uint8List imageBytes, String fileName, String userId) async {
    try {
      Logger.info('Starting registration image upload for user: $userId');
      Logger.debug('File name: $fileName');
      Logger.debug('Image size: ${imageBytes.length} bytes');

      // Create a unique file path
      final fileExtension = fileName.split('.').last.toLowerCase();
      final filePath = 'profiles/$userId/avatar.$fileExtension';
      Logger.debug('Upload path: $filePath');

      // Try uploading directly first (most efficient if bucket exists and is accessible)
      try {
        Logger.debug('Attempting direct upload to avatars bucket...');
        await _supabase.storage
            .from('avatars')
            .uploadBinary(filePath, imageBytes, fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ));
        
        final publicUrl = _supabase.storage
            .from('avatars')
            .getPublicUrl(filePath);
        
        Logger.info('Direct upload successful. Public URL: $publicUrl');
        return publicUrl;
      } catch (uploadError) {
        Logger.warning('Direct upload failed: $uploadError');
        
        // Check if bucket exists and attempt to create if needed
        final bucketReady = await _ensureAvatarsBucket();
        if (!bucketReady) {
          Logger.error('Failed to ensure avatars bucket exists');
          throw Exception('Avatar upload failed: Unable to access storage bucket');
        }
        
        // Retry upload after bucket verification/creation
        Logger.info('Retrying upload after bucket verification...');
      }

      // Retry upload after bucket setup
      Logger.debug('Uploading file to storage...');
      await _supabase.storage
          .from('avatars')
          .uploadBinary(filePath, imageBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ));

      // Get the public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      Logger.info('Upload successful. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      Logger.error('Error uploading registration image: $e');
      Logger.error('Error type: ${e.runtimeType}');
      if (e is StorageException) {
        Logger.error('Storage error details: ${e.message}');
      }
      rethrow; // Re-throw to let the controller handle it
    }
  }

  Future<String?> uploadProfileImage(Uint8List imageBytes, String fileName) async {
    try {
      final user = currentUser;
      if (user == null) {
        Logger.error('Upload failed: No user logged in');
        throw Exception('No user logged in');
      }

      Logger.info('Starting image upload for user: ${user.id}');
      Logger.debug('File name: $fileName');
      Logger.debug('Image size: ${imageBytes.length} bytes');

      // Create a unique file path
      final fileExtension = fileName.split('.').last.toLowerCase();
      final filePath = 'profiles/${user.id}/avatar.$fileExtension';
      Logger.debug('Upload path: $filePath');

      // Try uploading directly first (most efficient if bucket exists and is accessible)
      try {
        Logger.debug('Attempting direct upload to avatars bucket...');
        await _supabase.storage
            .from('avatars')
            .uploadBinary(filePath, imageBytes, fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ));
        
        final publicUrl = _supabase.storage
            .from('avatars')
            .getPublicUrl(filePath);
        
        Logger.info('Direct upload successful. Public URL: $publicUrl');
        return publicUrl;
      } catch (uploadError) {
        Logger.warning('Direct upload failed: $uploadError');
        
        // Check if bucket exists and attempt to create if needed
        final bucketReady = await _ensureAvatarsBucket();
        if (!bucketReady) {
          Logger.error('Failed to ensure avatars bucket exists');
          throw Exception('Avatar upload failed: Unable to access storage bucket');
        }
        
        // Retry upload after bucket verification/creation
        Logger.info('Retrying upload after bucket verification...');
      }

      // Retry upload after bucket setup
      Logger.debug('Uploading file to storage...');
      await _supabase.storage
          .from('avatars')
          .uploadBinary(filePath, imageBytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ));

      // Get the public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      Logger.info('Upload successful. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      Logger.error('Error uploading profile image: $e');
      Logger.error('Error type: ${e.runtimeType}');
      if (e is StorageException) {
        Logger.error('Storage error details: ${e.message}');
      }
      rethrow; // Re-throw to let the controller handle it
    }
  }

  Future<void> updateUserProfileImage(String userId, String profileImageUrl) async {
    try {
      Logger.debug('Updating user profile image for user: $userId');
      Logger.debug('Image URL: $profileImageUrl');
      
      final result = await _supabase
          .from('users')
          .update({'profile_image_url': profileImageUrl})
          .eq('id', userId)
          .select();
      
      Logger.debug('User profile image update result: $result');
      Logger.info('User profile image updated successfully');
    } catch (e) {
      Logger.error('Failed to update user profile image: $e');
      if (e is PostgrestException) {
        Logger.error('Postgrest details - message: ${e.message}, code: ${e.code}');
      }
      rethrow;
    }
  }

  Future<bool> hasPermission(UserRole requiredRole) async {
    try {
      final userProfile = await getCurrentUserProfile();
      if (userProfile == null) return false;

      switch (requiredRole) {
        case UserRole.admin:
          return userProfile.role == UserRole.admin;
        case UserRole.choirLeader:
          return userProfile.role == UserRole.admin || 
                 userProfile.role == UserRole.choirLeader;
        case UserRole.choirMember:
          return true;
      }
    } catch (e) {
      Logger.error('Error checking permissions: $e');
      return false;
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
        'last_login': DateTime.now().toIso8601String(),
      })
          .eq('id', userId);
    } catch (e) {
      Logger.error('Error updating last login: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      // First deactivate the user in the database
      await _supabase
          .from('users')
          .update({
            'is_active': false,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Then delete the auth user (this will automatically sign them out)
      await _supabase.auth.admin.deleteUser(user.id);
      
      // Sign out the user locally
      await signOut();
      
    } catch (e) {
      Logger.error('Error deleting account: $e');
      rethrow;
    }
  }

  /// Ensure the avatars bucket exists
  Future<bool> _ensureAvatarsBucket() async {
    try {
      Logger.debug('Checking if avatars bucket exists...');
      
      // Strategy 1: Try to access the bucket directly
      try {
        await _supabase.storage.from('avatars').list();
        Logger.info('avatars bucket found and accessible');
        return true;
      } catch (accessError) {
        Logger.warning('Direct bucket access failed: $accessError');
        
        // Strategy 2: Check if bucket exists in list
        try {
          final buckets = await _supabase.storage.listBuckets();
          final bucketExists = buckets.any((bucket) => bucket.name == 'avatars');
          
          if (bucketExists) {
            Logger.warning('avatars bucket found in list but may have access issues');
            return true;
          }
        } catch (listError) {
          Logger.error('Listing buckets failed: $listError');
        }
      }

      Logger.info('avatars bucket does not exist, attempting to create...');

      // Strategy 3: Try to create bucket
      try {
        await _supabase.storage.createBucket(
          'avatars',
          const BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
          ),
        );
        Logger.info('Successfully created avatars bucket');
        return true;
      } catch (createError) {
        Logger.error('Failed to create avatars bucket: $createError');
        Logger.error('MANUAL ACTION REQUIRED: Please ask a system administrator to create the storage bucket');
        Logger.info('Storage bucket setup steps:');
        Logger.info('1. Go to Supabase Dashboard > Storage > Buckets');
        Logger.info('2. Click "New bucket"');
        Logger.info('3. Name: avatars');
        Logger.info('4. Make it public: YES');
        Logger.info('5. Allow file types: image/jpeg, image/png, image/gif, image/webp');
        return false;
      }
    } catch (e) {
      Logger.error('Error during avatars bucket initialization: $e');
      return false;
    }
  }

  String _handleAuthException(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password.';
      case 'User not found':
        return 'No user found with this email address.';
      case 'Invalid email':
        return 'The email address is not valid.';
      case 'Email not confirmed':
        return 'Please check your email and confirm your account.';
      case 'Too many requests':
        return 'Too many requests. Please try again later.';
      default:
        return e.message;
    }
  }
}