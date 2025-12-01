import 'package:flutter/material.dart';
import 'package:jagar/models/scanHistory_model.dart';
import 'package:provider/provider.dart';
import '../providers/scan_history_provider.dart';

class EventScanHistoryPage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const EventScanHistoryPage({
    Key? key,
    required this.eventId,
    required this.eventName,
  }) : super(key: key);

  @override
  State<EventScanHistoryPage> createState() => _EventScanHistoryPageState();
}

class _EventScanHistoryPageState extends State<EventScanHistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    final provider = Provider.of<ScanHistoryProvider>(context, listen: false);
    // Load all scan history, nanti kita filter by event
    await provider.getScanHistoryByEvent(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B0000),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Riwayat Scan Tiket',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B0000),
                          ),
                        ),
                        Text(
                          widget.eventName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF7B0000)),
                    onPressed: _loadScanHistory,
                  ),
                ],
              ),
            ),

            // Red line
            Container(
              color: const Color(0xFF7B0000),
              height: 8,
            ),

            // Statistics Bar
            Consumer<ScanHistoryProvider>(
              builder: (context, provider, _) {
                final totalScans = provider.scanHistories.length;
                
                return Container(
                  color: const Color(0xFF7B0000),
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Color(0xFF7B0000),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Scan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$totalScans Tiket',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7B0000),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Scan History List
            Expanded(
              child: Consumer<ScanHistoryProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadScanHistory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF7B0000),
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.scanHistories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat scan',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadScanHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.scanHistories.length,
                      itemBuilder: (context, index) {
                        final scanHistory = provider.scanHistories[index];
                        return ScanHistoryCard(
                          scanHistory: scanHistory,
                          index: index,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Scan History Card
// ============================================

class ScanHistoryCard extends StatelessWidget {
  final ScanHistory scanHistory;
  final int index;

  const ScanHistoryCard({
    Key? key,
    required this.scanHistory,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Data dari relasi (asumsi sudah di-load dengan eager loading)
    final petugas = scanHistory.user; // User yang melakukan scan
    final tiket = scanHistory.tiket; // Tiket yang di-scan
    final pemilikTiket = tiket?.transaksi?.user; // User pemilik tiket

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan nomor dan waktu
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B0000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Berhasil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF7B0000),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(scanHistory.scanTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hadir',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Info Pemilik Tiket
            _buildInfoSection(
              icon: Icons.person,
              title: 'Pemilik Tiket',
              name: pemilikTiket?.nama ?? 'Unknown',
              email: pemilikTiket?.email,
              phone: pemilikTiket?.phone,
            ),

            const SizedBox(height: 12),

            // Info Petugas yang Scan
            _buildInfoSection(
              icon: Icons.badge,
              title: 'Di-scan oleh',
              name: petugas?.nama ?? 'Unknown',
              email: petugas?.email,
              phone: petugas?.phone,
              iconColor: const Color(0xFF7B0000),
            ),

            const SizedBox(height: 12),

            // Info Tiket
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Code',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          tiket?.qrCode ?? '-',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String name,
    String? email,
    String? phone,
    Color iconColor = Colors.blue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (email != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (phone != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute';
  }
}