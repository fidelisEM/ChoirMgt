import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class MockDataService {
  factory MockDataService() => _instance;
  MockDataService._internal();
  static final MockDataService _instance = MockDataService._internal();

  final Uuid _uuid = const Uuid();

  // Keys for SharedPreferences
  static const String _choirsKey = 'choirs';
  static const String _choirMembersKey = 'choir_members';

  // Initialize with sample data if empty
  Future<void> initializeSampleData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we already have data
    if (prefs.getString(_choirsKey) != null) return;

    // Create sample choirs
    final sampleChoirs = [
      ChoirModel(
        id: _uuid.v4(),
        name: 'Grace Cathedral Choir',
        description: 'Main church choir for Sunday services and special events',
        leaderId: 'leader-1',
        adminId: 'admin-1',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
        memberCount: 25,
      ),
      ChoirModel(
        id: _uuid.v4(),
        name: 'Youth Worship Team',
        description: 'Contemporary worship team for youth services',
        leaderId: 'leader-2',
        adminId: 'admin-1',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isActive: true,
        memberCount: 12,
      ),
      ChoirModel(
        id: _uuid.v4(),
        name: 'Children\'s Choir',
        description: 'Choir for children ages 6-12',
        leaderId: 'leader-3',
        adminId: 'admin-1',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        isActive: true,
        memberCount: 18,
      ),
    ];

    // Save sample data
    final choirsJson = jsonEncode(
      sampleChoirs.map((choir) => choir.toJson()).toList(),
    );
    await prefs.setString(_choirsKey, choirsJson);
  }

  // CHOIR OPERATIONS
  Future<List<ChoirModel>> getAllChoirs() async {
    await initializeSampleData();
    final prefs = await SharedPreferences.getInstance();
    final choirsJson = prefs.getString(_choirsKey);

    if (choirsJson == null) return [];

    final List<dynamic> choirsData = jsonDecode(choirsJson);
    return choirsData.map((data) => ChoirModel.fromJson(data)).toList();
  }

  Future<String> createChoir(ChoirModel choir) async {
    final choirId = _uuid.v4();
    final choirWithId = choir.copyWith(id: choirId);

    final choirs = await getAllChoirs();
    choirs.add(choirWithId);

    final prefs = await SharedPreferences.getInstance();
    final choirsJson = jsonEncode(choirs.map((c) => c.toJson()).toList());
    await prefs.setString(_choirsKey, choirsJson);

    return choirId;
  }

  Future<ChoirModel?> getChoirById(String choirId) async {
    final choirs = await getAllChoirs();
    try {
      return choirs.firstWhere((choir) => choir.id == choirId);
    } catch (e) {
      return null;
    }
  }

  Future<List<ChoirModel>> getChoirsByAdmin(String adminId) async {
    final choirs = await getAllChoirs();
    return choirs
        .where((choir) => choir.adminId == adminId && choir.isActive)
        .toList();
  }

  Future<List<ChoirModel>> getChoirsByLeader(String leaderId) async {
    final choirs = await getAllChoirs();
    return choirs
        .where((choir) => choir.leaderId == leaderId && choir.isActive)
        .toList();
  }

  Future<bool> updateChoir(ChoirModel choir) async {
    final choirs = await getAllChoirs();
    final index = choirs.indexWhere((c) => c.id == choir.id);

    if (index == -1) return false;

    choirs[index] = choir;

    final prefs = await SharedPreferences.getInstance();
    final choirsJson = jsonEncode(choirs.map((c) => c.toJson()).toList());
    await prefs.setString(_choirsKey, choirsJson);

    return true;
  }

  Future<bool> deleteChoir(String choirId) async {
    final choirs = await getAllChoirs();
    final initialLength = choirs.length;
    choirs.removeWhere((choir) => choir.id == choirId);

    if (choirs.length == initialLength) return false;

    final prefs = await SharedPreferences.getInstance();
    final choirsJson = jsonEncode(choirs.map((c) => c.toJson()).toList());
    await prefs.setString(_choirsKey, choirsJson);

    return true;
  }

  Future<List<ChoirModel>> searchChoirs(String query) async {
    final choirs = await getAllChoirs();
    final lowerQuery = query.toLowerCase();

    return choirs
        .where(
          (choir) =>
              choir.name.toLowerCase().contains(lowerQuery) ||
              choir.description.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  // CHOIR MEMBER OPERATIONS
  Future<List<ChoirMemberModel>> getChoirMembers(String choirId) async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = prefs.getString('${_choirMembersKey}_$choirId');

    if (membersJson == null) {
      // Create some sample members for the first choir
      final choirs = await getAllChoirs();
      if (choirs.isNotEmpty && choirId == choirs.first.id) {
        return _createSampleMembers(choirId);
      }
      return [];
    }

    final List<dynamic> membersData = jsonDecode(membersJson);
    return membersData.map((data) => ChoirMemberModel.fromJson(data)).toList();
  }

  Future<List<ChoirMemberModel>> _createSampleMembers(String choirId) async {
    final sampleMembers = [
      ChoirMemberModel(
        id: _uuid.v4(),
        userId: 'user-1',
        choirId: choirId,
        registrationNumber: 'CM001',
        joinDate: DateTime.now().subtract(const Duration(days: 20)),
        status: MemberStatus.active,
      ),
      ChoirMemberModel(
        id: _uuid.v4(),
        userId: 'user-2',
        choirId: choirId,
        registrationNumber: 'CM002',
        joinDate: DateTime.now().subtract(const Duration(days: 15)),
        status: MemberStatus.active,
      ),
      ChoirMemberModel(
        id: _uuid.v4(),
        userId: 'user-3',
        choirId: choirId,
        registrationNumber: 'CM003',
        joinDate: DateTime.now().subtract(const Duration(days: 10)),
        status: MemberStatus.active,
      ),
    ];

    // Save sample members
    final prefs = await SharedPreferences.getInstance();
    final membersJson = jsonEncode(
      sampleMembers.map((m) => m.toJson()).toList(),
    );
    await prefs.setString('${_choirMembersKey}_$choirId', membersJson);

    return sampleMembers;
  }

  Future<String> addMemberToChoir(ChoirMemberModel member) async {
    final memberId = _uuid.v4();
    final memberWithId = member.copyWith(id: memberId);

    final members = await getChoirMembers(member.choirId);
    members.add(memberWithId);

    final prefs = await SharedPreferences.getInstance();
    final membersJson = jsonEncode(members.map((m) => m.toJson()).toList());
    await prefs.setString('${_choirMembersKey}_${member.choirId}', membersJson);

    // Update choir member count
    await _updateChoirMemberCount(member.choirId);

    return memberId;
  }

  Future<bool> removeMemberFromChoir(String memberId, String choirId) async {
    final members = await getChoirMembers(choirId);
    final initialLength = members.length;
    members.removeWhere((member) => member.id == memberId);

    if (members.length == initialLength) return false;

    final prefs = await SharedPreferences.getInstance();
    final membersJson = jsonEncode(members.map((m) => m.toJson()).toList());
    await prefs.setString('${_choirMembersKey}_$choirId', membersJson);

    // Update choir member count
    await _updateChoirMemberCount(choirId);

    return true;
  }

  Future<void> _updateChoirMemberCount(String choirId) async {
    final members = await getChoirMembers(choirId);
    final activeMembers = members
        .where((m) => m.status == MemberStatus.active)
        .length;

    final choir = await getChoirById(choirId);
    if (choir != null) {
      final updatedChoir = choir.copyWith(memberCount: activeMembers);
      await updateChoir(updatedChoir);
    }
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
