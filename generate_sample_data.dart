#!/usr/bin/env dart

import 'dart:io';
import 'lib/services/sample_data_service.dart';

Future<void> main() async {
  print('🚀 Choir Management System - Sample Data Generator');
  print('=====================================================');
  print('');

  final service = SampleDataService();

  try {
    print('Generating comprehensive sample data...');
    print('This includes users, choirs, memberships, and activities.');
    print('');

    await service.generateAllSampleData();

    print('');
    print('✅ Sample data generation completed successfully!');
    print('');
    print('📊 What was generated:');
    print('   • 13 realistic users (1 admin, 3 choir leaders, 9 members)');
    print('   • 5 diverse choirs with different characteristics:');
    print('     - St. Mary\'s Cathedral Choir (Traditional)');
    print('     - Harmony Youth Ensemble (Contemporary)');
    print('     - Gospel Voices United (Gospel)');
    print('     - Chamber Singers (Advanced)');
    print('     - Christmas Carol Ensemble (Seasonal)');
    print('   • 30+ choir memberships with realistic attendance data');
    print('   • Activity feed with recent events and updates');
    print('   • Realistic payment and fee records');
    print('');
    print(
      '🎯 You can now run the app and see all features working with real data!',
    );
    print('   Run: flutter run');
    print('');
    print('📧 Sample user accounts you can use:');
    print('   Admin: admin@choirms.com');
    print('   Leader: michael.conductor@email.com');
    print('   Member: alice.soprano@email.com');
    print('');
  } catch (e) {
    print('❌ Error generating sample data: $e');
    exit(1);
  }
}
