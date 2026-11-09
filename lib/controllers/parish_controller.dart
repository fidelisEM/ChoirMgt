import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/models.dart';
import '../services/parish_service.dart';

class ParishController extends GetxController {
  final ParishService _parishService = ParishService();

  var isLoading = false.obs;
  var parishes = <ParishModel>[].obs;
  var selectedParish = Rxn<ParishModel>();
  var selectedArchdioceseId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    fetchParishes();
  }

  Future<void> fetchParishes({String? archdioceseId}) async {
    try {
      isLoading.value = true;
      final fetchedParishes = await _parishService.getParishes(
        archdioceseId: archdioceseId ?? selectedArchdioceseId.value,
      );
      parishes.value = fetchedParishes;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch parishes: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchParishesByArchdiocese(String archdioceseId) async {
    try {
      isLoading.value = true;
      selectedArchdioceseId.value = archdioceseId;
      final fetchedParishes = await _parishService.getParishesByArchdiocese(
        archdioceseId,
      );
      parishes.value = fetchedParishes;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch parishes for archdiocese: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createParish(ParishModel parish) async {
    try {
      isLoading.value = true;
      final newParish = await _parishService.createParish(parish);
      parishes.add(newParish);
      Get.snackbar(
        'Success',
        'Parish created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create parish: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateParish(ParishModel parish) async {
    try {
      isLoading.value = true;
      final updatedParish = await _parishService.updateParish(parish);
      final index = parishes.indexWhere((p) => p.id == parish.id);
      if (index != -1) {
        parishes[index] = updatedParish;
      }
      Get.snackbar(
        'Success',
        'Parish updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update parish: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteParish(String id) async {
    try {
      isLoading.value = true;
      await _parishService.deleteParish(id);
      parishes.removeWhere((p) => p.id == id);
      Get.snackbar(
        'Success',
        'Parish deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete parish: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectParish(ParishModel? parish) {
    selectedParish.value = parish;
  }

  void selectArchdiocese(String? archdioceseId) {
    if (selectedArchdioceseId.value != archdioceseId) {
      selectedArchdioceseId.value = archdioceseId;
      selectedParish.value = null;
      if (archdioceseId != null) {
        fetchParishesByArchdiocese(archdioceseId);
      } else {
        parishes.clear();
      }
    }
  }

  void clearSelection() {
    selectedParish.value = null;
    selectedArchdioceseId.value = null;
    parishes.clear();
  }
}
