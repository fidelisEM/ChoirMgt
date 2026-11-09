import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/archdiocese_controller.dart';
import '../../controllers/parish_controller.dart';
import '../../models/models.dart';

class ArchdioceseParishManagementScreen extends StatelessWidget {
  const ArchdioceseParishManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archdioceseController = Get.put(ArchdioceseController());
    final parishController = Get.put(ParishController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Archdiocese & Parish Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Archdioceses', icon: Icon(Icons.location_city)),
              Tab(text: 'Parishes', icon: Icon(Icons.church)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildArchdioceseTab(archdioceseController),
            _buildParishTab(archdioceseController, parishController),
          ],
        ),
      ),
    );
  }

  Widget _buildArchdioceseTab(ArchdioceseController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Country',
                      prefixIcon: Icon(Icons.public),
                    ),
                    initialValue: controller.selectedCountry.value,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Countries'),
                      ),
                      ...controller.countries.map(
                        (country) => DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        ),
                      ),
                    ],
                    onChanged: (value) => controller.selectCountry(value),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showArchdioceseDialog(controller),
                icon: const Icon(Icons.add),
                label: const Text('Add Archdiocese'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.archdioceses.isEmpty) {
              return const Center(child: Text('No archdioceses found'));
            }

            return ListView.builder(
              itemCount: controller.archdioceses.length,
              itemBuilder: (context, index) {
                final archdiocese = controller.archdioceses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(archdiocese.name),
                    subtitle: Text(
                      '${archdiocese.country} - ${archdiocese.code}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showArchdioceseDialog(controller, archdiocese),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _showDeleteDialog(
                            context,
                            'Delete Archdiocese',
                            'Are you sure you want to delete ${archdiocese.name}?',
                            () => controller.deleteArchdiocese(archdiocese.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildParishTab(
    ArchdioceseController archdioceseController,
    ParishController parishController,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Archdiocese',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    initialValue: parishController.selectedArchdioceseId.value,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Archdioceses'),
                      ),
                      ...archdioceseController.archdioceses.map(
                        (archdiocese) => DropdownMenuItem<String>(
                          value: archdiocese.id,
                          child: Text(archdiocese.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        parishController.selectArchdiocese(value),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    _showParishDialog(archdioceseController, parishController),
                icon: const Icon(Icons.add),
                label: const Text('Add Parish'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (parishController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (parishController.parishes.isEmpty) {
              return const Center(child: Text('No parishes found'));
            }

            return ListView.builder(
              itemCount: parishController.parishes.length,
              itemBuilder: (context, index) {
                final parish = parishController.parishes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(parish.name),
                    subtitle: Text(
                      '${parish.archdioceseName} - ${parish.code}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showParishDialog(
                            archdioceseController,
                            parishController,
                            parish: parish,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _showDeleteDialog(
                            Get.context!,
                            'Delete Parish',
                            'Are you sure you want to delete ${parish.name}?',
                            () => parishController.deleteParish(parish.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  void _showArchdioceseDialog(
    ArchdioceseController controller, [
    ArchdioceseModel? archdiocese,
  ]) {
    final nameController = TextEditingController(text: archdiocese?.name ?? '');
    final codeController = TextEditingController(text: archdiocese?.code ?? '');
    final countryController = TextEditingController(
      text: archdiocese?.country ?? '',
    );
    final descriptionController = TextEditingController(
      text: archdiocese?.description ?? '',
    );
    final bishopController = TextEditingController(
      text: archdiocese?.bishop ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: Text(
          archdiocese == null ? 'Add Archdiocese' : 'Edit Archdiocese',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: bishopController,
                decoration: const InputDecoration(labelText: 'Bishop'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  codeController.text.trim().isEmpty ||
                  countryController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please fill in all required fields');
                return;
              }

              final newArchdiocese = ArchdioceseModel(
                id:
                    archdiocese?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                code: codeController.text.trim(),
                country: countryController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                bishop: bishopController.text.trim().isEmpty
                    ? null
                    : bishopController.text.trim(),
                createdAt: archdiocese?.createdAt ?? DateTime.now(),
              );

              if (archdiocese == null) {
                controller.createArchdiocese(newArchdiocese);
              } else {
                controller.updateArchdiocese(newArchdiocese);
              }

              Get.back();
            },
            child: Text(archdiocese == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showParishDialog(
    ArchdioceseController archdioceseController,
    ParishController parishController, {
    ParishModel? parish,
  }) {
    final nameController = TextEditingController(text: parish?.name ?? '');
    final codeController = TextEditingController(text: parish?.code ?? '');
    final addressController = TextEditingController(
      text: parish?.address ?? '',
    );
    final phoneController = TextEditingController(
      text: parish?.phoneNumber ?? '',
    );
    final emailController = TextEditingController(text: parish?.email ?? '');
    final pastorController = TextEditingController(text: parish?.pastor ?? '');

    String? selectedArchdioceseId = parish?.archdioceseId;

    Get.dialog(
      AlertDialog(
        title: Text(parish == null ? 'Add Parish' : 'Edit Parish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Code'),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Archdiocese'),
                initialValue: selectedArchdioceseId,
                items: archdioceseController.archdioceses
                    .map(
                      (archdiocese) => DropdownMenuItem<String>(
                        value: archdiocese.id,
                        child: Text(archdiocese.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => selectedArchdioceseId = value,
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: pastorController,
                decoration: const InputDecoration(labelText: 'Pastor'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  codeController.text.trim().isEmpty ||
                  selectedArchdioceseId == null) {
                Get.snackbar('Error', 'Please fill in all required fields');
                return;
              }

              final selectedArchdiocese = archdioceseController.archdioceses
                  .firstWhere((a) => a.id == selectedArchdioceseId);

              final newParish = ParishModel(
                id:
                    parish?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                code: codeController.text.trim(),
                archdioceseId: selectedArchdioceseId!,
                archdioceseName: selectedArchdiocese.name,
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                phoneNumber: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                pastor: pastorController.text.trim().isEmpty
                    ? null
                    : pastorController.text.trim(),
                createdAt: parish?.createdAt ?? DateTime.now(),
              );

              if (parish == null) {
                parishController.createParish(newParish);
              } else {
                parishController.updateParish(newParish);
              }

              Get.back();
            },
            child: Text(parish == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
