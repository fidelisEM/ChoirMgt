import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import '../services/archdiocese_service.dart';

class ArchdioceseController extends GetxController {
  final ArchdioceseService _archdioceseService = ArchdioceseService();
  
  var isLoading = false.obs;
  var archdioceses = <ArchdioceseModel>[].obs;
  var selectedArchdiocese = Rxn<ArchdioceseModel>();
  var countries = <String>[].obs;
  var selectedCountry = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchCountries();
    fetchArchdioceses();
  }

  Future<void> fetchCountries() async {
    try {
      isLoading.value = true;
      final fetchedCountries = await _archdioceseService.getCountries();
      countries.value = fetchedCountries;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch countries: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchArchdioceses({String? country}) async {
    try {
      isLoading.value = true;
      final fetchedArchdioceses = await _archdioceseService.getArchdioceses(
        country: country ?? selectedCountry.value,
      );
      archdioceses.value = fetchedArchdioceses;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch archdioceses: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createArchdiocese(ArchdioceseModel archdiocese) async {
    try {
      isLoading.value = true;
      final newArchdiocese = await _archdioceseService.createArchdiocese(archdiocese);
      archdioceses.add(newArchdiocese);
      Get.snackbar(
        'Success',
        'Archdiocese created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create archdiocese: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateArchdiocese(ArchdioceseModel archdiocese) async {
    try {
      isLoading.value = true;
      final updatedArchdiocese = await _archdioceseService.updateArchdiocese(archdiocese);
      final index = archdioceses.indexWhere((a) => a.id == archdiocese.id);
      if (index != -1) {
        archdioceses[index] = updatedArchdiocese;
      }
      Get.snackbar(
        'Success',
        'Archdiocese updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update archdiocese: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteArchdiocese(String id) async {
    try {
      isLoading.value = true;
      await _archdioceseService.deleteArchdiocese(id);
      archdioceses.removeWhere((a) => a.id == id);
      Get.snackbar(
        'Success',
        'Archdiocese deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete archdiocese: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectArchdiocese(ArchdioceseModel? archdiocese) {
    selectedArchdiocese.value = archdiocese;
  }

  void selectCountry(String? country) {
    selectedCountry.value = country;
    fetchArchdioceses(country: country);
  }

  void clearSelection() {
    selectedArchdiocese.value = null;
    selectedCountry.value = null;
  }
}