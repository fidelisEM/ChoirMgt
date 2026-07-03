import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/logger.dart';

class UserService {
  factory UserService() => _instance;
  UserService._internal();
  static final UserService _instance = UserService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson({
        'id': response['id'],
        ...response,
      });
    } catch (e) {
      Logger.error('Error getting user', e);
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('full_name');

      return response
          .map<UserModel>((data) => UserModel.fromJson(data))
          .toList();
    } catch (e) {
      Logger.error('Error getting all users', e);
      return [];
    }
  }

  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', role.toString().split('.').last)
          .order('full_name');

      return response
          .map<UserModel>((data) => UserModel.fromJson(data))
          .toList();
    } catch (e) {
      Logger.error('Error getting users by role', e);
      return [];
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      await _supabase
          .from('users')
          .update(user.toJson())
          .eq('id', user.id);
      return true;
    } catch (e) {
      Logger.error('Error updating user', e);
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': false})
          .eq('id', userId);
      return true;
    } catch (e) {
      Logger.error('Error deactivating user', e);
      return false;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': true})
          .eq('id', userId);
      return true;
    } catch (e) {
      Logger.error('Error activating user', e);
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _supabase
          .from('users')
          .update({'role': newRole.toString().split('.').last})
          .eq('id', userId);
      return true;
    } catch (e) {
      Logger.error('Error updating user role', e);
      return false;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .limit(1);

      if (response.isEmpty) return null;

      return UserModel.fromJson(response.first);
    } catch (e) {
      Logger.error('Error getting user by email', e);
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return getAllUsers();

      final response = await _supabase
          .from('users')
          .select()
          .or('full_name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%')
          .order('full_name');

      return response
          .map<UserModel>((data) => UserModel.fromJson(data))
          .toList();
    } catch (e) {
      Logger.error('Error searching users', e);
      return [];
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          if (data.isNotEmpty) {
            return UserModel.fromJson(data.first);
          }
          return null;
        });
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('full_name')
        .map((data) {
          return data
              .map<UserModel>((item) => UserModel.fromJson(item))
              .toList();
        });
  }
}