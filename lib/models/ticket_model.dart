import 'package:jagar/models/transaksi_model.dart';

class Ticket {
  final int idTiket;
  final int idTransaksi;
  final String qrCode;
  final String status; // 'aktif', 'digunakan', 'dibatalkan'
  final String kehadiran; // 'belum_hadir', 'hadir'
  final DateTime? createdAt;
  
  // Relasi dengan transaksi
  final Transaksi? transaksi;

  Ticket({
    required this.idTiket,
    required this.idTransaksi,
    required this.qrCode,
    required this.status,
    required this.kehadiran,
    this.createdAt,
    this.transaksi,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      idTiket: json['id_tiket'] ?? 0,
      idTransaksi: json['id_transaksi'] ?? 0,
      qrCode: json['qr_code'] ?? '',
      status: json['status'] ?? 'aktif',
      kehadiran: json['kehadiran'] ?? 'belum_hadir',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      transaksi: json['transaksi'] != null 
          ? Transaksi.fromJson(json['transaksi']) 
          : null,
    );
  }

  String get kehadiranText {
    return kehadiran == 'hadir' ? 'Hadir' : 'Belum Hadir';
  }

  bool get isHadir => kehadiran == 'hadir';

  toJson() {}
}