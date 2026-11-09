import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _initializeAuth();
  }
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  void _initializeAuth() {
    _authService.authStateChanges.listen((AuthState authState) async {
      try {
        if (authState.session?.user != null) {
          _currentUser = await _authService.getCurrentUserProfile();
        } else {
          _currentUser = null;
        }
        _clearError();
      } catch (e) {
        Logger.error('AuthController: Error in auth state change', e);
        _currentUser = null;
        _setError('Authentication error: $e');
      }
      notifyListeners();
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      _clearError();

      _currentUser = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    UserRole role = UserRole.choirMember,
    String suggestedChoir = '',
    dynamic profileImage, // Can be File (mobile) or Uint8List (web)
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // First register the user without profile image
      _currentUser = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        suggestedChoir: suggestedChoir,
        profileImageUrl: null, // Set to null initially
      );

      if (_currentUser != null && profileImage != null) {
        try {
          // Upload profile image after user is registered
          late Uint8List imageBytes;
          late String fileName;

          if (kIsWeb && profileImage is Uint8List) {
            // Web: profileImage is already Uint8List
            imageBytes = profileImage;
            fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          } else if (!kIsWeb && profileImage is File) {
            // Mobile: profileImage is File
            imageBytes = await profileImage.readAsBytes();
            fileName =
                'profile_${DateTime.now().millisecondsSinceEpoch}.${profileImage.path.split('.').last}';
          } else {
            throw Exception('Invalid image data type for current platform');
          }

          final profileImageUrl = await _authService.uploadRegistrationImage(
            imageBytes,
            fileName,
            _currentUser!.id,
          );

          if (profileImageUrl != null) {
            // Update user profile with image URL
            await _authService.updateUserProfileImage(
              _currentUser!.id,
              profileImageUrl,
            );

            // Refresh user data to include the new image URL
            _currentUser = await _authService.getCurrentUserProfile();
          }
        } catch (imageError) {
          Logger.error(
            'Failed to upload profile image during registration',
            imageError,
          );
          // Don't fail the entire registration if image upload fails
          // User can upload image later from profile screen
        }
      }

      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _currentUser = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      _currentUser = await _authService.signInWithGoogle();
      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      _setLoading(true);
      _clearError();

      _currentUser = await _authService.signInWithApple();
      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
    String? email,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        email: email,
      );

      _currentUser = await _authService.getCurrentUserProfile();
      _setLoading(false);
      notifyListeners(); // Ensure UI updates reflect the changes
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<String?> uploadProfileImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final imageUrl = await _authService.uploadProfileImage(
        imageBytes,
        fileName,
      );

      _setLoading(false);
      return imageUrl;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  Future<bool> hasPermission(UserRole requiredRole) async {
    return await _authService.hasPermission(requiredRole);
  }

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.deleteAccount();
      _currentUser = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isChoirLeader =>
      _currentUser?.role == UserRole.admin ||
      _currentUser?.role == UserRole.choirLeader;
  bool get isChoirMember => _currentUser?.role == UserRole.choirMember;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  Future<void> refreshCurrentUser() async {
    try {
      _setLoading(true);
      _currentUser = await _authService.getCurrentUserProfile();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Admin method to update any user's profile (for choir leaders/admins)
  Future<bool> updateUserProfileByUserId({
    required String userId,
    String? displayName,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updateUserProfileByUserId(
        userId: userId,
        displayName: displayName,
        phoneNumber: phoneNumber,
        email: email,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
