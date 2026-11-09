import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/member_service.dart';
import '../services/member_status_service.dart';

class MemberController extends ChangeNotifier {
  final MemberService _memberService = MemberService();
  final MemberStatusService _statusService = MemberStatusService();

  List<Map<String, dynamic>> _membersWithUserInfo = [];
  List<UserModel> _availableUsers = [];
  Map<String, dynamic> _memberStatistics = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get membersWithUserInfo => _membersWithUserInfo;
  List<UserModel> get availableUsers => _availableUsers;
  Map<String, dynamic> get memberStatistics => _memberStatistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load choir members with user information
  Future<void> loadChoirMembers(String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      _membersWithUserInfo = await _memberService.getChoirMembersWithUserInfo(
        choirId,
      );
      _memberStatistics = await _memberService.getMemberStatistics(choirId);

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load choir members: $e');
      _setLoading(false);
    }
  }

  // Add member to choir
  Future<bool> addMemberToChoir({
    required String userId,
    required String choirId,
    String? customRegistrationNumber,
    MemberRole role = MemberRole.choir,
    MemberLevel level = MemberLevel.choir,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Generate registration number if not provided
      final registrationNumber =
          customRegistrationNumber ??
          await _memberService.generateRegistrationNumber(choirId);

      final member = await _memberService.addMemberToChoir(
        userId: userId,
        choirId: choirId,
        registrationNumber: registrationNumber,
        role: role,
        level: level,
        metadata: metadata,
      );

      if (member != null) {
        // Reload members list
        await loadChoirMembers(choirId);
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to add member to choir');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error adding member: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove member from choir
  Future<bool> removeMemberFromChoir(String memberId, String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _memberService.removeMemberFromChoir(memberId);

      if (success) {
        // Reload members list
        await loadChoirMembers(choirId);
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to remove member from choir');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error removing member: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update member status
  Future<bool> updateMemberStatus({
    required String memberId,
    required MemberStatus status,
    required String choirId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedMember = await _memberService.updateMemberStatus(
        memberId: memberId,
        status: status,
      );

      if (updatedMember != null) {
        // Update local data
        final index = _membersWithUserInfo.indexWhere(
          (m) => m['id'] == memberId,
        );
        if (index != -1) {
          _membersWithUserInfo[index]['status'] = status
              .toString()
              .split('.')
              .last;
        }

        // Reload statistics
        _memberStatistics = await _memberService.getMemberStatistics(choirId);

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update member status');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating member status: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update member details
  Future<bool> updateMemberDetails({
    required String memberId,
    required String choirId,
    String? registrationNumber,
    double? outstandingFees,
    String? qrCode,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedMember = await _memberService.updateMemberDetails(
        memberId: memberId,
        registrationNumber: registrationNumber,
        outstandingFees: outstandingFees,
        qrCode: qrCode,
        metadata: metadata,
      );

      if (updatedMember != null) {
        // Reload members to get fresh data
        await loadChoirMembers(choirId);
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update member details');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating member details: $e');
      _setLoading(false);
      return false;
    }
  }

  // Search users to add to choir
  Future<void> searchAvailableUsers({
    required String choirId,
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) {
        _availableUsers = [];
        notifyListeners();
        return;
      }

      _setLoading(true);
      _clearError();

      _availableUsers = await _memberService.searchUsersToAdd(
        choirId: choirId,
        query: query.trim(),
      );
      _setLoading(false);
    } catch (e) {
      _availableUsers = [];
      _setError('Error searching users: $e');
      _setLoading(false);
    }
  }

  // Generate registration number
  Future<String> generateRegistrationNumber(String choirId) async {
    return await _memberService.generateRegistrationNumber(choirId);
  }

  // Update member role
  Future<bool> updateMemberRole({
    required String memberId,
    required String choirId,
    required String newRole,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _memberService.updateMemberRole(
        memberId: memberId,
        newRole: newRole,
      );

      if (success) {
        // Update local data
        final memberIndex = _membersWithUserInfo.indexWhere(
          (m) => m['id'] == memberId,
        );
        if (memberIndex != -1) {
          _membersWithUserInfo[memberIndex]['role'] = newRole;
        }

        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update member role');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating member role: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update member level
  Future<bool> updateMemberLevel({
    required String memberId,
    required String choirId,
    required String newLevel,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _memberService.updateMemberLevel(
        memberId: memberId,
        newLevel: newLevel,
      );

      if (success) {
        // Update local data
        final memberIndex = _membersWithUserInfo.indexWhere(
          (m) => m['id'] == memberId,
        );
        if (memberIndex != -1) {
          _membersWithUserInfo[memberIndex]['level'] = newLevel;
        }
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update member level');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating member level: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get member by ID from current list
  Map<String, dynamic>? getMemberById(String memberId) {
    try {
      return _membersWithUserInfo.firstWhere(
        (member) => member['id'] == memberId,
      );
    } catch (e) {
      return null;
    }
  }

  // Clear data
  void clearData() {
    _membersWithUserInfo.clear();
    _availableUsers.clear();
    _memberStatistics.clear();
    _clearError();
    notifyListeners();
  }

  // Private helper methods
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
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Automatic status management
  Future<void> runAutomaticStatusUpdate(String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      await _statusService.updateAllMemberStatuses(choirId);

      // Reload members to reflect status changes
      await loadChoirMembers(choirId);
      _setLoading(false);
    } catch (e) {
      _setError('Error running automatic status update: $e');
      _setLoading(false);
    }
  }

  Future<MemberStatus> checkMemberStatus(
    String memberId,
    String choirId,
  ) async {
    try {
      final memberData = getMemberById(memberId);
      if (memberData == null) {
        throw Exception('Member not found');
      }

      return await _statusService.checkMemberStatus(
        memberId,
        choirId,
        memberData,
      );
    } catch (e) {
      throw Exception('Error checking member status: $e');
    }
  }

  Map<String, dynamic> getAutomationRules() {
    return _statusService.getAutomationRules();
  }
}
