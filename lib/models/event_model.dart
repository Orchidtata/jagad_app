class Event {
  final int idEvent;
  final String namaEvent;
  final String? deskripsi;
  final String? banner;
  final String? lokasi;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool? isLayar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Event({
    required this.idEvent,
    required this.namaEvent,
    this.deskripsi,
    this.banner,
    this.lokasi,
    this.startTime,
    this.endTime,
    this.isLayar,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      idEvent: json['id_event'] ?? 0,
      namaEvent: json['nama_event'] ?? '',
      deskripsi: json['deskripsi'],
      banner: json['banner'],
      lokasi: json['lokasi'],
      startTime: json['start_time'] != null 
          ? DateTime.tryParse(json['start_time']) 
          : null,
      endTime: json['end_time'] != null 
          ? DateTime.tryParse(json['end_time']) 
          : null,
      isLayar: json['berbayar'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_event': idEvent,
      'nama_event': namaEvent,
      'deskripsi': deskripsi,
      'banner': banner,
      'lokasi': lokasi,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'berbayar': isLayar,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}