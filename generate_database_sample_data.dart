#!/usr/bin/env dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/database_sample_data_service.dart';

Future<void> main() async {
  print('🚀 Choir Management System - Database Sample Data Generator');
  print('============================================================');
  print('');

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    print(
      '❌ Set SUPABASE_URL and SUPABASE_ANON_KEY in the environment before running this script.',
    );
    exit(1);
  }

  // Initialize Supabase
  try {
    print('🔌 Connecting to Supabase...');
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('✅ Connected to Supabase successfully');
  } catch (e) {
    print('❌ Failed to connect to Supabase: $e');
    exit(1);
  }

  final service = DatabaseSampleDataService();

  try {
    // Check if sample data already exists
    print('🔍 Checking if sample data already exists...');
    final exists = await service.sampleDataExists();

    if (exists) {
      print(
        '⚠️  Sample data already exists. Do you want to clear it first? (y/N)',
      );
      final input = stdin.readLineSync();
      if (input?.toLowerCase() == 'y' || input?.toLowerCase() == 'yes') {
        await service.clearAllSampleData();
        print('✅ Existing sample data cleared');
      } else {
        print('❌ Cancelled - sample data already exists');
        exit(0);
      }
    }

    print('');
    print('📊 Generating comprehensive database sample data...');
    print('This will create real records in your Supabase database:');
    print('   • Users table: Admin, choir leaders, and members');
    print('   • Choirs table: 5 diverse choirs');
    print('   • Choir_members table: Realistic memberships');
    print('');

    await service.generateAllSampleData();

    print('');
    print('🎉 Database sample data generation completed successfully!');
    print('');
    print('📊 What was created in your database:');
    print('   • 10 users across different roles:');
    print('     - 1 Admin: admin@choirms.com');
    print(
      '     - 3 Choir Leaders: michael.conductor@email.com, emily.harmony@email.com, david.music@email.com',
    );
    print(
      '     - 6 Members: alice.soprano@email.com, james.tenor@email.com, etc.',
    );
    print('   • 5 choirs with realistic data:');
    print('     - St. Mary\'s Cathedral Choir (Traditional)');
    print('     - Harmony Youth Ensemble (Contemporary)');
    print('     - Gospel Voices United (Gospel Music)');
    print('     - Chamber Singers (Advanced Classical)');
    print('     - Christmas Carol Ensemble (Seasonal)');
    print('   • 9 choir memberships with attendance and payment data');
    print('');
    print('🎯 You can now run the app and see all features working!');
    print('   Run: flutter run');
    print('');
    print('🔐 Login with any of these accounts:');
    print('   Admin: admin@choirms.com (password: set in your auth system)');
    print('   Leader: michael.conductor@email.com');
    print('   Member: alice.soprano@email.com');
    print('');
    print('✨ All the implemented features will now work with real data:');
    print('   ✓ Member names displayed correctly (not user IDs)');
    print('   ✓ Calculated attendance statistics');
    print('   ✓ Dynamic activity feed');
    print('   ✓ Working edit forms with user lookup');
    print('   ✓ Image upload functionality');
    print('');
  } catch (e) {
    print('❌ Error generating sample data: $e');
    print('');
    print('💡 Common issues:');
    print('   • Check your Supabase connection');
    print('   • Ensure your database tables exist');
    print('   • Verify your Supabase credentials in supabase_options.dart');
    exit(1);
  }
}
