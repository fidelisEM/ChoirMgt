import 'package:choir_management_system/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses snake_case keys from Supabase', () {
      final user = UserModel.fromJson({
        'id': 'abc123',
        'email': 'leader@example.com',
        'full_name': 'Jane Leader',
        'phone_number': '+254700000000',
        'role': 'choirLeader',
        'created_at': '2026-01-01T00:00:00.000Z',
        'last_login': '2026-02-01T00:00:00.000Z',
        'is_active': true,
        'profile_image_url': 'https://example.com/avatar.png',
      });

      expect(user.id, 'abc123');
      expect(user.email, 'leader@example.com');
      expect(user.fullName, 'Jane Leader');
      expect(user.phoneNumber, '+254700000000');
      expect(user.role, UserRole.choirLeader);
      expect(user.isActive, true);
      expect(user.profileImageUrl, 'https://example.com/avatar.png');
      expect(user.lastLogin, DateTime.parse('2026-02-01T00:00:00.000Z'));
    });

    test('falls back to camelCase keys when snake_case is absent', () {
      final user = UserModel.fromJson({
        'id': 'abc123',
        'email': 'a@example.com',
        'fullName': 'A B',
        'phoneNumber': '123',
        'role': 'admin',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(user.fullName, 'A B');
      expect(user.phoneNumber, '123');
      expect(user.role, UserRole.admin);
    });

    test('defaults to choirMember for an unrecognized or missing role', () {
      final user = UserModel.fromJson({
        'id': 'abc123',
        'email': 'a@example.com',
        'created_at': '2026-01-01T00:00:00.000Z',
        'role': 'superuser',
      });

      expect(user.role, UserRole.choirMember);
    });

    test('defaults isActive to true and lastLogin to null when absent', () {
      final user = UserModel.fromJson({
        'id': 'abc123',
        'email': 'a@example.com',
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(user.isActive, true);
      expect(user.lastLogin, isNull);
    });
  });

  group('UserModel.toJson', () {
    test('round-trips id/email/role and serializes role as its enum name', () {
      final user = UserModel(
        id: 'u1',
        email: 'admin@example.com',
        fullName: 'Admin User',
        phoneNumber: '000',
        role: UserRole.admin,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final json = user.toJson();

      expect(json['id'], 'u1');
      expect(json['email'], 'admin@example.com');
      expect(json['full_name'], 'Admin User');
      expect(json['phone_number'], '000');
      // This exact string must match the RLS policies in
      // database/migrations/003_add_users_rls.sql, which compare
      // public.users.role against the literal 'choirMember' / 'admin'.
      expect(json['role'], 'admin');
    });

    test('self-registration payload always serializes role as choirMember', () {
      final user = UserModel(
        id: 'u2',
        email: 'newuser@example.com',
        fullName: 'New User',
        phoneNumber: '',
        role: UserRole.choirMember,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      expect(user.toJson()['role'], 'choirMember');
    });
  });

  group('UserModel.copyWith', () {
    test('overrides only the specified fields', () {
      final original = UserModel(
        id: 'u1',
        email: 'a@example.com',
        fullName: 'A',
        phoneNumber: '1',
        role: UserRole.choirMember,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final updated = original.copyWith(
        fullName: 'B',
        role: UserRole.choirLeader,
      );

      expect(updated.fullName, 'B');
      expect(updated.role, UserRole.choirLeader);
      expect(updated.id, original.id);
      expect(updated.email, original.email);
    });
  });

  group('UserModel.isAdmin', () {
    UserModel withRole(UserRole role) => UserModel(
      id: 'u',
      email: 'e@example.com',
      fullName: 'n',
      phoneNumber: '',
      role: role,
      createdAt: DateTime.utc(2026),
    );

    test('is true only for admin and superAdmin', () {
      expect(withRole(UserRole.superAdmin).isAdmin, isTrue);
      expect(withRole(UserRole.admin).isAdmin, isTrue);
      expect(withRole(UserRole.choirLeader).isAdmin, isFalse);
      expect(withRole(UserRole.choirMember).isAdmin, isFalse);
    });
  });
}
