import 'package:jagar/models/ticket_model.dart';
import 'package:jagar/models/user_model.dart';

class ScanHistory {
  final int? idScan;
  final int idTiket;
  final int idUser;
  final DateTime scanTime;
  final DateTime? createdAt;
  // Relasi
  final User? user; // Petugas yang scan
  final Ticket? tiket; // Tiket yang di-scan

  ScanHistory({
    this.idScan,
    required this.idTiket,
    required this.idUser,
    required this.scanTime,
    this.createdAt,
    this.user,
    this.tiket,
  });

  // From JSON
  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      idScan: json['id_scan'] != null
          ? int.parse(json['id_scan'].toString())
          : null,
      idTiket: int.parse(json['id_tiket'].toString()),
      idUser: int.parse(json['id_user'].toString()),
      scanTime: DateTime.parse(json['scan_time']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      tiket: json['tiket'] != null ? Ticket.fromJson(json['tiket']) : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id_scan': idScan,
      'id_tiket': idTiket,
      'id_user': idUser,
      'scan_time': scanTime.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'user': user?.toJson(),
      'tiket': tiket?.toJson(),
    };
  }

  // To Map untuk insert ke database
  Map<String, dynamic> toMap() {
    return {
      'id_tiket': idTiket,
      'id_user': idUser,
      'scan_time': scanTime.toIso8601String(),
    };
  }
}
