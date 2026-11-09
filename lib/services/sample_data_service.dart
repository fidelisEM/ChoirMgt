import '../models/models.dart';
import '../utils/logger.dart';
import 'activity_service.dart';

class SampleDataService {
  final ActivityService _activityService = ActivityService();

  // Generate comprehensive sample data for the choir management system
  Future<void> generateAllSampleData() async {
    try {
      Logger.info('Starting sample data generation...');

      // Step 1: Create sample users
      final users = await _generateSampleUsers();
      Logger.info('Generated ${users.length} sample users');

      // Step 2: Create sample choirs
      final choirs = await _generateSampleChoirs(users);
      Logger.info('Generated ${choirs.length} sample choirs');

      // Step 3: Create choir memberships
      await _generateChoirMemberships(choirs, users);
      Logger.info('Generated choir memberships');

      // Step 4: Generate activities
      await _generateSampleActivities(choirs);
      Logger.info('Generated sample activities');

      Logger.info('Sample data generation completed successfully!');
    } catch (e) {
      Logger.error('Error generating sample data', e);
      rethrow;
    }
  }

  // Generate diverse sample users
  Future<List<UserModel>> _generateSampleUsers() async {
    final sampleUsers = [
      // Administrators
      UserModel(
        id: 'admin_001',
        email: 'admin@choirms.com',
        fullName: 'Sarah Johnson',
        phoneNumber: '+1234567890',
        role: UserRole.admin,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1494790108755-2616c9d7b2e2?w=150',
      ),

      // Choir Leaders
      UserModel(
        id: 'leader_001',
        email: 'michael.conductor@email.com',
        fullName: 'Michael Rodriguez',
        phoneNumber: '+1234567891',
        role: UserRole.choirLeader,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      ),

      UserModel(
        id: 'leader_002',
        email: 'emily.harmony@email.com',
        fullName: 'Emily Chen',
        phoneNumber: '+1234567892',
        role: UserRole.choirLeader,
        createdAt: DateTime.now().subtract(const Duration(days: 280)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      ),

      UserModel(
        id: 'leader_003',
        email: 'david.music@email.com',
        fullName: 'David Thompson',
        phoneNumber: '+1234567893',
        role: UserRole.choirLeader,
        createdAt: DateTime.now().subtract(const Duration(days: 250)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      ),

      // Choir Members
      UserModel(
        id: 'member_001',
        email: 'alice.soprano@email.com',
        fullName: 'Alice Williams',
        phoneNumber: '+1234567894',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150',
      ),

      UserModel(
        id: 'member_002',
        email: 'james.tenor@email.com',
        fullName: 'James Davis',
        phoneNumber: '+1234567895',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      ),

      UserModel(
        id: 'member_003',
        email: 'maria.alto@email.com',
        fullName: 'Maria Garcia',
        phoneNumber: '+1234567896',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 170)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      ),

      UserModel(
        id: 'member_004',
        email: 'robert.bass@email.com',
        fullName: 'Robert Wilson',
        phoneNumber: '+1234567897',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 160)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
      ),

      UserModel(
        id: 'member_005',
        email: 'linda.soprano@email.com',
        fullName: 'Linda Anderson',
        phoneNumber: '+1234567898',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      ),

      UserModel(
        id: 'member_006',
        email: 'carlos.tenor@email.com',
        fullName: 'Carlos Martinez',
        phoneNumber: '+1234567899',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 140)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
      ),

      UserModel(
        id: 'member_007',
        email: 'jennifer.alto@email.com',
        fullName: 'Jennifer Lee',
        phoneNumber: '+1234567900',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 130)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      ),

      UserModel(
        id: 'member_008',
        email: 'thomas.bass@email.com',
        fullName: 'Thomas Brown',
        phoneNumber: '+1234567901',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1547425260-76bcadfb4f2c?w=150',
      ),

      UserModel(
        id: 'member_009',
        email: 'susan.soprano@email.com',
        fullName: 'Susan Miller',
        phoneNumber: '+1234567902',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 110)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=150',
      ),

      UserModel(
        id: 'member_010',
        email: 'kevin.tenor@email.com',
        fullName: 'Kevin Taylor',
        phoneNumber: '+1234567903',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1552374196-c4e7ffc6e126?w=150',
      ),

      UserModel(
        id: 'member_011',
        email: 'patricia.alto@email.com',
        fullName: 'Patricia Jones',
        phoneNumber: '+1234567904',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=150',
      ),

      UserModel(
        id: 'member_012',
        email: 'daniel.bass@email.com',
        fullName: 'Daniel White',
        phoneNumber: '+1234567905',
        role: UserRole.choirMember,
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        isActive: true,
        profileImageUrl:
            'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      ),
    ];

    // In a real implementation, these would be saved to the database
    // For now, we'll just return them for use in generating other data
    return sampleUsers;
  }

  // Generate sample choirs with different characteristics
  Future<List<ChoirModel>> _generateSampleChoirs(List<UserModel> users) async {
    final admin = users.firstWhere((u) => u.role == UserRole.admin);
    final leaders = users.where((u) => u.role == UserRole.choirLeader).toList();

    final sampleChoirs = [
      ChoirModel(
        id: 'choir_001',
        name: 'St. Mary\'s Cathedral Choir',
        description:
            'A prestigious cathedral choir with over 50 years of tradition. We perform classical and contemporary sacred music for Sunday services, weddings, and special events.',
        leaderId: leaders[0].id,
        adminId: admin.id,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
        memberCount: 24,
        imageUrl:
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300',
        tags: ['Sacred', 'Traditional', 'Cathedral', 'Classical'],
        location: '123 Cathedral Street, Downtown',
        schedule: 'Sundays 10:00 AM, Wednesdays 7:00 PM',
      ),

      ChoirModel(
        id: 'choir_002',
        name: 'Harmony Youth Ensemble',
        description:
            'An energetic youth choir focused on contemporary Christian music and community outreach. Perfect for young singers aged 13-25.',
        leaderId: leaders[1].id,
        adminId: admin.id,
        createdAt: DateTime.now().subtract(const Duration(days: 280)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
        memberCount: 18,
        imageUrl:
            'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=300',
        tags: ['Youth', 'Contemporary', 'Outreach', 'Modern'],
        location: 'Community Center, 456 Oak Avenue',
        schedule: 'Saturdays 2:00 PM',
      ),

      ChoirModel(
        id: 'choir_003',
        name: 'Gospel Voices United',
        description:
            'A soulful gospel choir bringing the joy and power of gospel music to our community. All skill levels welcome!',
        leaderId: leaders[2].id,
        adminId: admin.id,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
        memberCount: 16,
        imageUrl:
            'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=300',
        tags: ['Gospel', 'Soulful', 'Community', 'All Levels'],
        location: 'Grace Baptist Church, 789 Pine Street',
        schedule: 'Thursdays 6:30 PM, Sundays 9:00 AM',
      ),

      ChoirModel(
        id: 'choir_004',
        name: 'Chamber Singers',
        description:
            'An intimate chamber choir specializing in Renaissance and Baroque music. Advanced singers only.',
        leaderId: leaders[0].id, // Michael can lead multiple choirs
        adminId: admin.id,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
        memberCount: 12,
        imageUrl:
            'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=300',
        tags: ['Chamber', 'Renaissance', 'Baroque', 'Advanced'],
        location: 'Music Conservatory, 321 Elm Street',
        schedule: 'Tuesdays 7:00 PM',
      ),

      ChoirModel(
        id: 'choir_005',
        name: 'Christmas Carol Ensemble',
        description:
            'A seasonal choir that performs traditional and modern Christmas carols during the holiday season.',
        leaderId: leaders[1].id,
        adminId: admin.id,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        isActive: false, // Seasonal choir, currently inactive
        memberCount: 20,
        imageUrl:
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300',
        tags: ['Seasonal', 'Christmas', 'Carols', 'Holiday'],
        location: 'Town Square, Main Street',
        schedule: 'December only - Saturdays 3:00 PM',
      ),
    ];

    return sampleChoirs;
  }

  // Generate choir memberships
  Future<void> _generateChoirMemberships(
    List<ChoirModel> choirs,
    List<UserModel> users,
  ) async {
    final members = users.where((u) => u.role == UserRole.choirMember).toList();

    // St. Mary's Cathedral Choir - Large, established choir
    final stMarysChoir = choirs[0];
    for (int i = 0; i < members.length; i++) {
      final member = members[i];

      Logger.debug(
        'Created membership: ${member.fullName} -> ${stMarysChoir.name}',
      );
    }

    // Harmony Youth Ensemble - Smaller, more active
    final youthChoir = choirs[1];
    for (int i = 0; i < 8 && i < members.length; i++) {
      final member = members[i + 4]; // Different members

      Logger.debug(
        'Created membership: ${member.fullName} -> ${youthChoir.name}',
      );
    }

    // Gospel Voices United - Mix of experience levels
    final gospelChoir = choirs[2];
    for (int i = 0; i < 6 && i < members.length; i++) {
      final member = members[i + 6]; // Different members again

      Logger.debug(
        'Created membership: ${member.fullName} -> ${gospelChoir.name}',
      );
    }
  }

  // Generate realistic activities
  Future<void> _generateSampleActivities(List<ChoirModel> choirs) async {
    for (final choir in choirs) {
      // Generate member joined activities
      await _activityService.recordActivity(
        choirId: choir.id,
        userId: 'system',
        type: ActivityType.memberJoined,
        title: 'New member joined',
        description: 'Alice Williams joined the choir',
        metadata: {'member_name': 'Alice Williams'},
      );

      await _activityService.recordActivity(
        choirId: choir.id,
        userId: 'system',
        type: ActivityType.attendanceRecorded,
        title: 'Attendance recorded',
        description: 'Sunday morning service - 18 members present',
        metadata: {'session': 'Sunday Service', 'attendees': 18},
      );

      await _activityService.recordActivity(
        choirId: choir.id,
        userId: 'system',
        type: ActivityType.paymentReceived,
        title: 'Payment received',
        description: 'James Davis paid monthly dues (\$50.00)',
        metadata: {'member_name': 'James Davis', 'amount': 50.0},
      );

      await _activityService.recordActivity(
        choirId: choir.id,
        userId: 'system',
        type: ActivityType.choirUpdated,
        title: 'Choir information updated',
        description: 'Schedule and location information updated',
        metadata: {
          'updated_fields': ['schedule', 'location'],
        },
      );

      await _activityService.recordActivity(
        choirId: choir.id,
        userId: 'system',
        type: ActivityType.eventCreated,
        title: 'New event created',
        description: 'Christmas Concert scheduled for December 15th',
        metadata: {'event_name': 'Christmas Concert', 'date': '2024-12-15'},
      );
    }

    Logger.info('Generated activities for ${choirs.length} choirs');
  }

  // Quick method to generate basic test data
  Future<void> generateQuickTestData() async {
    Logger.info('Generating quick test data...');

    Logger.info('Quick test data generated');
  }
}
