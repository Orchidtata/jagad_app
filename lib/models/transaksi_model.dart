import 'package:jagar/models/jenisTiket_model.dart';
import 'package:jagar/models/user_model.dart';

class Transaksi {
  final int idTransaksi;
  final int idUser;
  final int idJenisTiket;
  final int jumlahTiket;
  final double totalHarga;
  final DateTime? waktuTransaksi;
  final String status; // 'pending', 'paid', 'failed', 'expired'
  final String? paymentType;
  final DateTime? transactionTime;
  final String? orderId;
  
  // Relasi
  final User? user;
  final JenisTiket? jenisTiket;

  Transaksi({
    required this.idTransaksi,
    required this.idUser,
    required this.idJenisTiket,
    required this.jumlahTiket,
    required this.totalHarga,
    this.waktuTransaksi,
    required this.status,
    this.paymentType,
    this.transactionTime,
    this.orderId,
    this.user,
    this.jenisTiket,
  });

  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      idTransaksi: json['id_transaksi'] ?? 0,
      idUser: json['id_user'] ?? 0,
      idJenisTiket: json['id_jenis_tiket'] ?? 0,
      jumlahTiket: json['jumlah_tiket'] ?? 0,
      totalHarga: double.tryParse(json['total_harga']?.toString() ?? '0') ?? 0.0,
      waktuTransaksi: json['waktu_transaksi'] != null 
          ? DateTime.tryParse(json['waktu_transaksi']) 
          : null,
      status: json['status'] ?? 'pending',
      paymentType: json['payment_type'],
      transactionTime: json['transaction_time'] != null 
          ? DateTime.tryParse(json['transaction_time']) 
          : null,
      orderId: json['order_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      jenisTiket: json['jenis_tiket'] != null 
          ? JenisTiket.fromJson(json['jenis_tiket']) 
          : null,
    );
  }
}