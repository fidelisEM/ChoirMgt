import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../utils/logger.dart';

class DatabaseSampleDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate all sample data and insert into database
  Future<void> generateAllSampleData() async {
    try {
      Logger.info('Starting database sample data generation...');

      // Step 1: Create sample users
      final users = await _insertSampleUsers();
      Logger.info('Inserted ${users.length} sample users');

      // Step 2: Create sample choirs
      final choirs = await _insertSampleChoirs(users);
      Logger.info('Inserted ${choirs.length} sample choirs');

      // Step 3: Create choir memberships
      await _insertChoirMemberships(choirs, users);
      Logger.info('Inserted choir memberships');

      // Step 4: Generate sample activities (if activities table exists)
      // await _insertSampleActivities(choirs);
      Logger.info('Sample data generation completed successfully!');
    } catch (e) {
      Logger.error('Error generating sample data', e);
      rethrow;
    }
  }

  // Insert sample users into the database
  Future<List<UserModel>> _insertSampleUsers() async {
    final sampleUsers = [
      // Administrator
      {
        'id': 'admin_001',
        'email': 'admin@choirms.com',
        'full_name': 'Sarah Johnson',
        'phone_number': '+1234567890',
        'role': 'admin',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 365))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1494790108755-2616c9d7b2e2?w=150',
      },

      // Choir Leaders
      {
        'id': 'leader_001',
        'email': 'michael.conductor@email.com',
        'full_name': 'Michael Rodriguez',
        'phone_number': '+1234567891',
        'role': 'choirLeader',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 300))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      },

      {
        'id': 'leader_002',
        'email': 'emily.harmony@email.com',
        'full_name': 'Emily Chen',
        'phone_number': '+1234567892',
        'role': 'choirLeader',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 280))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      },

      {
        'id': 'leader_003',
        'email': 'david.music@email.com',
        'full_name': 'David Thompson',
        'phone_number': '+1234567893',
        'role': 'choirLeader',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 250))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      },

      // Choir Members
      {
        'id': 'member_001',
        'email': 'alice.soprano@email.com',
        'full_name': 'Alice Williams',
        'phone_number': '+1234567894',
        'role': 'choirMember',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 200))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150',
      },

      {
        'id': 'member_002',
        'email': 'james.tenor@email.com',
        'full_name': 'James Davis',
        'phone_number': '+1234567895',
        'role': 'choirMember',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 180))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      },

      {
        'id': 'member_003',
        'email': 'maria.alto@email.com',
        'full_name': 'Maria Garcia',
        'phone_number': '+1234567896',
        'role': 'choirMember',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 170))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      },

      {
        'id': 'member_004',
        'email': 'robert.bass@email.com',
        'full_name': 'Robert Wilson',
        'phone_number': '+1234567897',
        'role': 'choirMember',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 160))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150',
      },

      {
        'id': 'member_005',
        'email': 'linda.soprano@email.com',
        'full_name': 'Linda Anderson',
        'phone_number': '+1234567898',
        'role': 'choirMember',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 150))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      },

      {
        'id': 'member_006',
        'email': 'carlos.tenor@email.com',
        'full_name': 'Carlos Martinez',
        'phone_number': '+1234567899',
        'role': 'choirMember',
        'created_at': DateTime.now()
            .subtract(const Duration(days: 140))
            .toIso8601String(),
        'is_active': true,
        'profile_image_url':
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
      },
    ];

    // Insert users into database
    for (final userData in sampleUsers) {
      try {
        await _supabase.from('users').insert(userData);
        Logger.debug('Inserted user: ${userData['full_name']}');
      } catch (e) {
        Logger.error('Error inserting user ${userData['full_name']}', e);
        // Continue with next user if this one fails
      }
    }

    return sampleUsers.map((data) => UserModel.fromJson(data)).toList();
  }

  // Insert sample choirs
  Future<List<ChoirModel>> _insertSampleChoirs(List<UserModel> users) async {
    final admin = users.firstWhere((u) => u.role == UserRole.admin);
    final leaders = users.where((u) => u.role == UserRole.choirLeader).toList();

    final sampleChoirs = [
      {
        'id': 'choir_001',
        'name': 'St. Mary\'s Cathedral Choir',
        'description':
            'A prestigious cathedral choir with over 50 years of tradition. We perform classical and contemporary sacred music for Sunday services, weddings, and special events.',
        'leader_id': leaders[0].id,
        'admin_id': admin.id,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 365))
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 10))
            .toIso8601String(),
        'is_active': true,
        'member_count': 24,
        'image_url':
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=300',
        'tags': ['Sacred', 'Traditional', 'Cathedral', 'Classical'],
        'location': '123 Cathedral Street, Downtown',
        'schedule': 'Sundays 10:00 AM, Wednesdays 7:00 PM',
      },

      {
        'id': 'choir_002',
        'name': 'Harmony Youth Ensemble',
        'description':
            'An energetic youth choir focused on contemporary Christian music and community outreach. Perfect for young singers aged 13-25.',
        'leader_id': leaders[1].id,
        'admin_id': admin.id,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 280))
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
        'is_active': true,
        'member_count': 18,
        'image_url':
            'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=300',
        'tags': ['Youth', 'Contemporary', 'Outreach', 'Modern'],
        'location': 'Community Center, 456 Oak Avenue',
        'schedule': 'Saturdays 2:00 PM',
      },

      {
        'id': 'choir_003',
        'name': 'Gospel Voices United',
        'description':
            'A soulful gospel choir bringing the joy and power of gospel music to our community. All skill levels welcome!',
        'leader_id': leaders[2].id,
        'admin_id': admin.id,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 200))
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'is_active': true,
        'member_count': 16,
        'image_url':
            'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=300',
        'tags': ['Gospel', 'Soulful', 'Community', 'All Levels'],
        'location': 'Grace Baptist Church, 789 Pine Street',
        'schedule': 'Thursdays 6:30 PM, Sundays 9:00 AM',
      },

      {
        'id': 'choir_004',
        'name': 'Chamber Singers',
        'description':
            'An intimate chamber choir specializing in Renaissance and Baroque music. Advanced singers only.',
        'leader_id': leaders[0].id,
        'admin_id': admin.id,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 150))
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'is_active': true,
        'member_count': 12,
        'image_url':
            'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=300',
        'tags': ['Chamber', 'Renaissance', 'Baroque', 'Advanced'],
        'location': 'Music Conservatory, 321 Elm Street',
        'schedule': 'Tuesdays 7:00 PM',
      },

      {
        'id': 'choir_005',
        'name': 'Christmas Carol Ensemble',
        'description':
            'A seasonal choir that performs traditional and modern Christmas carols during the holiday season.',
        'leader_id': leaders[1].id,
        'admin_id': admin.id,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 100))
            .toIso8601String(),
        'updated_at': DateTime.now()
            .subtract(const Duration(hours: 12))
            .toIso8601String(),
        'is_active': false,
        'member_count': 20,
        'image_url':
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300',
        'tags': ['Seasonal', 'Christmas', 'Carols', 'Holiday'],
        'location': 'Town Square, Main Street',
        'schedule': 'December only - Saturdays 3:00 PM',
      },
    ];

    // Insert choirs into database
    for (final choirData in sampleChoirs) {
      try {
        await _supabase.from('choirs').insert(choirData);
        Logger.debug('Inserted choir: ${choirData['name']}');
      } catch (e) {
        Logger.error('Error inserting choir ${choirData['name']}', e);
        // Continue with next choir if this one fails
      }
    }

    return sampleChoirs.map((data) => ChoirModel.fromJson(data)).toList();
  }

  // Insert choir memberships
  Future<void> _insertChoirMemberships(
    List<ChoirModel> choirs,
    List<UserModel> users,
  ) async {
    final members = users.where((u) => u.role == UserRole.choirMember).toList();

    // St. Mary's Cathedral Choir - Most members
    final stMarysChoir = choirs[0];
    for (int i = 0; i < members.length && i < 6; i++) {
      final member = members[i];
      final membershipData = {
        'id': 'membership_${stMarysChoir.id}_${member.id}',
        'user_id': member.id,
        'choir_id': stMarysChoir.id,
        'registration_number': 'STM${(i + 1).toString().padLeft(3, '0')}',
        'join_date': DateTime.now()
            .subtract(Duration(days: 365 - (i * 15)))
            .toIso8601String(),
        'status': i < 4 ? 'active' : (i < 5 ? 'inactive' : 'active'),
        'total_attendances': (75 + (i * 3)).clamp(10, 120),
        'total_absences': (25 - (i * 2)).clamp(5, 30),
        'outstanding_fees': i % 3 == 0 ? (50.0 + (i * 25)) : 0.0,
        'total_paid': 300.0 + (i * 50),
        'last_attendance': DateTime.now()
            .subtract(Duration(days: 7 + (i * 2)))
            .toIso8601String(),
        'metadata': {},
      };

      try {
        await _supabase.from('choir_members').insert(membershipData);
        Logger.debug(
          'Inserted membership: ${member.fullName} -> ${stMarysChoir.name}',
        );
      } catch (e) {
        Logger.error('Error inserting membership', e);
      }
    }

    // Add some members to other choirs too
    if (choirs.length > 1 && members.length > 2) {
      final youthChoir = choirs[1];
      for (int i = 0; i < 3 && i + 2 < members.length; i++) {
        final member = members[i + 2];
        final membershipData = {
          'id': 'membership_${youthChoir.id}_${member.id}',
          'user_id': member.id,
          'choir_id': youthChoir.id,
          'registration_number': 'HYE${(i + 1).toString().padLeft(3, '0')}',
          'join_date': DateTime.now()
              .subtract(Duration(days: 200 - (i * 10)))
              .toIso8601String(),
          'status': 'active',
          'total_attendances': (85 + (i * 2)).clamp(50, 100),
          'total_absences': (15 - i).clamp(5, 20),
          'outstanding_fees': 0.0,
          'total_paid': 150.0 + (i * 25),
          'last_attendance': DateTime.now()
              .subtract(Duration(days: 3 + i))
              .toIso8601String(),
          'metadata': {},
        };

        try {
          await _supabase.from('choir_members').insert(membershipData);
          Logger.debug(
            'Inserted membership: ${member.fullName} -> ${youthChoir.name}',
          );
        } catch (e) {
          Logger.error('Error inserting youth choir membership', e);
        }
      }
    }
  }

  // Clear all sample data (useful for testing)
  Future<void> clearAllSampleData() async {
    try {
      Logger.info('Clearing existing sample data...');

      // Delete in reverse order due to foreign key constraints
      await _supabase.from('choir_members').delete().like('id', 'membership_%');
      await _supabase.from('choirs').delete().like('id', 'choir_%');
      await _supabase.from('users').delete().like('id', 'admin_%');
      await _supabase.from('users').delete().like('id', 'leader_%');
      await _supabase.from('users').delete().like('id', 'member_%');

      Logger.info('Sample data cleared successfully');
    } catch (e) {
      Logger.error('Error clearing sample data', e);
      rethrow;
    }
  }

  // Check if sample data already exists
  Future<bool> sampleDataExists() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', 'admin@choirms.com')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
