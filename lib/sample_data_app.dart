import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/admin/sample_data_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const SampleDataApp());
}

class SampleDataApp extends StatelessWidget {
  const SampleDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Choir Management - Sample Data Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SampleDataScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
