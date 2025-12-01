class JenisTiket {
  final int idJenisTiket;
  final int idEvent;
  final String namaTiket;
  final double harga;
  final int? kuota;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  JenisTiket({
    required this.idJenisTiket,
    required this.idEvent,
    required this.namaTiket,
    required this.harga,
    this.kuota,
    this.createdAt,
    this.updatedAt,
  });

  factory JenisTiket.fromJson(Map<String, dynamic> json) {
    return JenisTiket(
      idJenisTiket: json['id_jenis_tiket'] ?? 0,
      idEvent: json['id_event'] ?? 0,
      namaTiket: json['nama_tiket'] ?? '',
      harga: double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0,
      kuota: json['kuota'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }
}