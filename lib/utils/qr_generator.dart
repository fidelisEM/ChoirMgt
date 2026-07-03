import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGenerator {
  static String generateMemberQRData(String registrationNumber, String choirId) {
    // Simple format: registrationNumber|choirId
    return '$registrationNumber|$choirId';
  }

  static Widget buildQRCodeWidget(String data, {double size = 200}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size - 32,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }

  static Widget buildMemberQRCard({
    required String fullName,
    required String registrationNumber,
    required String choirId,
    double qrSize = 150,
  }) {
    final qrData = generateMemberQRData(registrationNumber, choirId);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Member QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            buildQRCodeWidget(qrData, size: qrSize),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Reg: $registrationNumber',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan this code for attendance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}