import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:jagar/providers/ticket_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan Tiket",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF7B0000),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          _buildQrView(context),
          
          // Overlay info
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Arahkan kamera ke QR Code tiket',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memproses check-in...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrKey,
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFF7B0000),
        borderRadius: 12,
        borderLength: 40,
        borderWidth: 8,
        cutOutSize: MediaQuery.of(context).size.width * 0.75,
      ),
      onQRViewCreated: _onQRViewCreated,
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);
    
    controller.scannedDataStream.listen((scanData) async {
      if (!_isProcessing && scanData.code != null && scanData.code!.isNotEmpty) {
        setState(() => _isProcessing = true);
        controller.pauseCamera();

        try {
          // ✅ Gunakan TicketProvider yang sudah pakai ApiService
          final ticketProvider = Provider.of<TicketProvider>(
            context,
            listen: false,
          );

          print('🔍 Scanning QR Code: ${scanData.code}');

          // ✅ Scan ticket dengan token di header
          final result = await ticketProvider.scanTicket(scanData.code!);

          if (result['success'] == true) {
            // ✅ Show success dialog
            await _showSuccessDialog(context, result);
            
            // ✅ Kembali ke halaman sebelumnya dengan status success
            if (mounted) {
              Navigator.pop(context, true);
            }
          } else {
            // ❌ Show error dialog
            await _showErrorDialog(
              'Check-in Gagal',
              result['message'] ?? 'Terjadi kesalahan',
            );
            
            // Resume camera untuk scan ulang
            controller.resumeCamera();
          }
        } catch (e) {
          print('❌ Error scanning ticket: $e');
          
          await _showErrorDialog(
            'Error',
            'Terjadi kesalahan: ${e.toString()}',
          );
          
          controller.resumeCamera();
        } finally {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      }
    });
  }

  /// ✅ Show success dialog dengan detail tiket
  Future<void> _showSuccessDialog(
    BuildContext context,
    Map<String, dynamic> result,
  ) async {
    final data = result['data'] ?? {};
    final ticket = data['ticket'] ?? {};
    final user = data['user'] ?? {};
    final event = data['event'] ?? {};
    final jenisTiket = data['jenis_tiket'] ?? {};

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Check-in Berhasil!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('👤 Peserta'),
              _buildInfoRow('Nama', user['nama'] ?? '-'),
              if (user['email'] != null)
                _buildInfoRow('Email', user['email']),
              
              const SizedBox(height: 16),
              _buildSectionTitle('🎟 Tiket'),
              _buildInfoRow('Jenis', jenisTiket['nama_tiket'] ?? '-'),
              _buildInfoRow('Status', ticket['status'] ?? '-'),
              if (ticket['used_at'] != null)
                _buildInfoRow('Check-in', ticket['used_at']),
              
              const SizedBox(height: 16),
              _buildSectionTitle('📍 Event'),
              _buildInfoRow('Nama', event['nama_event'] ?? '-'),
              if (event['lokasi'] != null)
                _buildInfoRow('Lokasi', event['lokasi']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF7B0000),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  /// ✅ Show error dialog
  Future<void> _showErrorDialog(String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 48,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  /// Helper: Section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF7B0000),
          fontSize: 14,
        ),
      ),
    );
  }

  /// Helper: Info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}