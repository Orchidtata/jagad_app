// participant_confirm_screen.dart
import 'package:flutter/material.dart';

class ParticipantConfirmScreen extends StatelessWidget {
  final Map<String, String> dataPeserta;

  const ParticipantConfirmScreen({super.key, required this.dataPeserta});

  @override
  Widget build(BuildContext context) {
    final nama = dataPeserta['nama'] ?? '-';
    final nip = dataPeserta['nip'] ?? '-';
    final jabatan = dataPeserta['jabatan'] ?? '-';
    final instansi = dataPeserta['instansi'] ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFF7B0000),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Image.asset('assets/logo_badung.jpg', height: 35),
            const SizedBox(width: 8),
            const Text("JAGAD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            const Text("BADUNG", style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    field("Nama", nama),
                    const SizedBox(height: 8),
                    field("NIP", nip),
                    const SizedBox(height: 8),
                    field("Jabatan", jabatan),
                    const SizedBox(height: 8),
                    field("Instansi", instansi),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context), // cancel
                    child: const Text("Batal", style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      // kembalikan data peserta ke pemanggil (QRScannerScreen -> EventScreen)
                      Navigator.pop(context, dataPeserta);
                    },
                    child: const Text("Konfirmasi Hadir", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}
