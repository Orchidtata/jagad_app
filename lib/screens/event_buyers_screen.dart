import 'package:flutter/material.dart';
import 'package:jagar/models/ticket_model.dart';
import 'package:jagar/providers/ticket_provider.dart';
import 'package:jagar/screens/QRScreen.dart';
import 'package:jagar/screens/activity_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class EventBuyersScreen extends StatefulWidget {
  final int eventId;
  final String eventName;

  const EventBuyersScreen({
    Key? key,
    required this.eventId,
    required this.eventName,
  }) : super(key: key);

  @override
  State<EventBuyersScreen> createState() => _EventBuyersScreenState();
}

class _EventBuyersScreenState extends State<EventBuyersScreen> {
  String _filterKehadiran = 'semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TicketProvider>(context, listen: false);
      provider.fetchEventTickets(widget.eventId);
      provider.fetchEventStatistics(widget.eventId);
    });
  }

  // 🆕 Function untuk download CSV
  Future<void> _downloadCSV() async {
    try {
      final provider = Provider.of<TicketProvider>(context, listen: false);

      if (provider.tickets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk didownload'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Buat data CSV
      List<List<dynamic>> csvData = [
        [
          'No',
          'Nama Pembeli',
          'Email',
          'No. Telepon',
          'Jenis Tiket',
          'Harga',
          'Status Kehadiran',
          'QR Code',
          'Waktu Pembelian',
        ],
      ];

      // Tambahkan data tiket
      for (int i = 0; i < provider.tickets.length; i++) {
        final ticket = provider.tickets[i];
        final user = ticket.transaksi?.user;
        final jenisTiket = ticket.transaksi?.jenisTiket;

        csvData.add([
          i + 1,
          user?.nama ?? '-',
          user?.email ?? '-',
          user?.phone ?? '-',
          jenisTiket?.namaTiket ?? '-',
          'Rp ${jenisTiket?.harga ?? 0}',
          ticket.kehadiranText,
          ticket.qrCode ?? '-',
          ticket.createdAt ?? '-',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'Pembeli_${widget.eventName.replaceAll(' ', '_')}_$timestamp.csv';

      if (Platform.isAndroid) {
        // Request storage permission for Android
        final status = await Permission.storage.request();

        if (status.isGranted ||
            await Permission.manageExternalStorage.request().isGranted) {
          // Save to Downloads folder
          final directory = Directory('/storage/emulated/0/Download');

          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsString(csv);

          // Close loading
          Navigator.pop(context);

          // Show success dialog
          _showSuccessDialog(filePath);
        } else {
          // Permission denied, use share instead
          Navigator.pop(context);
          await _shareCSV(csv, fileName);
        }
      } else {
        // For iOS, use share
        Navigator.pop(context);
        await _shareCSV(csv, fileName);
      }
    } catch (e) {
      // Close loading if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🆕 Share CSV file (alternative untuk iOS atau jika permission ditolak)
  Future<void> _shareCSV(String csvContent, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Data Pembeli - ${widget.eventName}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🆕 Show success dialog
  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              'Download Berhasil!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'File CSV berhasil disimpan di:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
                          'Daftar Pembeli Tiket',
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
                  // 🆕 Download CSV Button
                  IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF7B0000)),
                    tooltip: 'Download CSV',
                    onPressed: _downloadCSV,
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Color(0xFF7B0000)),
                    tooltip: 'Riwayat Scan',
                    onPressed: () async {
                      // Navigate ke ScanHistoryPage dengan eventId
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventScanHistoryPage(
                            eventId: widget.eventId,
                            eventName: widget.eventName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Red line
            Container(
              color: const Color(0xFF7B0000),
              height: 8,
            ),

            // Statistics Cards
            Consumer<TicketProvider>(
              builder: (context, provider, _) {
                final totalPembeli = provider.totalTickets;
                final totalHadir = provider.totalHadir;
                final totalBelumHadir = provider.totalBelumHadir;

                return Container(
                  color: const Color(0xFF7B0000),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Pembeli',
                          totalPembeli.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Hadir',
                          totalHadir.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Belum Hadir',
                          totalBelumHadir.toString(),
                          Icons.schedule,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Search, Filter & Page Dropdown
            Consumer<TicketProvider>(
              builder: (context, provider, _) {
                return Container(
                  color: const Color(0xFF7B0000),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Cari nama pembeli...',
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Filter kehadiran
                      PopupMenuButton<String>(
                        icon:
                            const Icon(Icons.filter_list, color: Colors.white),
                        onSelected: (value) {
                          setState(() {
                            _filterKehadiran = value;
                          });
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'semua',
                            child: Text('Semua'),
                          ),
                          PopupMenuItem(
                            value: 'hadir',
                            child: Text('Hadir'),
                          ),
                          PopupMenuItem(
                            value: 'belum_hadir',
                            child: Text('Belum Hadir'),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),

                      // Dropdown halaman
                      DropdownButton<int>(
                        dropdownColor: Colors.white,
                        value: provider.currentPage,
                        style: const TextStyle(color: Colors.black),
                        items: List.generate(provider.lastPage, (index) {
                          final page = index + 1;
                          return DropdownMenuItem<int>(
                            value: page,
                            child: Text('Hal $page'),
                          );
                        }),
                        onChanged: (page) {
                          if (page != null) {
                            provider.fetchEventTickets(widget.eventId,
                                page: page);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // Buyers List
            Expanded(
              child: Consumer<TicketProvider>(
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
                                  color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  provider.fetchEventTickets(widget.eventId),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter dan pencarian
                  List<Ticket> filteredTickets = provider.tickets;

                  if (_filterKehadiran == 'hadir') {
                    filteredTickets = provider.hadirTickets;
                  } else if (_filterKehadiran == 'belum_hadir') {
                    filteredTickets = provider.belumHadirTickets;
                  }

                  if (_searchQuery.isNotEmpty) {
                    filteredTickets = filteredTickets.where((t) {
                      final namaPembeli =
                          t.transaksi?.user?.nama.toLowerCase() ?? '';
                      return namaPembeli.contains(_searchQuery);
                    }).toList();
                  }

                  if (filteredTickets.isEmpty) {
                    return const Center(
                      child: Text(
                        'Tidak ada pembeli ditemukan',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchEventTickets(widget.eventId),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = filteredTickets[index];
                        return BuyerCard(ticket: ticket, index: index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7B0000),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QrScannerScreen(),
            ),
          );

          if (result == true) {
            Provider.of<TicketProvider>(context, listen: false)
              ..fetchEventTickets(widget.eventId)
              ..fetchEventStatistics(widget.eventId);
          }
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================
// Buyer Card (tidak ada perubahan)
// ============================================

class BuyerCard extends StatelessWidget {
  final Ticket ticket;
  final int index;

  const BuyerCard({
    Key? key,
    required this.ticket,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = ticket.transaksi?.user;
    final jenisTiket = ticket.transaksi?.jenisTiket;
    final isHadir = ticket.isHadir;

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
        padding: const EdgeInsets.all(12),
        child: Row(
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
                  Text(
                    user?.nama ?? 'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF7B0000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (user?.email != null)
                    Row(
                      children: [
                        Icon(Icons.email, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user!.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (user?.phone != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          user!.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      jenisTiket?.namaTiket ?? 'Unknown Ticket',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isHadir ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHadir ? Colors.green : Colors.orange,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isHadir ? Icons.check_circle : Icons.schedule,
                    color: isHadir ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.kehadiranText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isHadir
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
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
}
