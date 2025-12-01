import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jagar/services/api_config.dart';
import 'package:jagar/models/ticket_model.dart';

class TicketService {
  /// Ambil daftar tiket (dengan pagination)
  Future<Map<String, dynamic>> getEventTickets(int eventId,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/tiket/event/$eventId/tickets?page=$page'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Tickets Status: ${response.statusCode}');
      print('Tickets Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          final List<dynamic> ticketList = data['data'] ?? [];

          final tickets = ticketList
              .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
              .toList();

          return {
            'tickets': tickets,
            'currentPage': data['current_page'] ?? 1,
            'lastPage': data['last_page'] ?? 1,
            'total': data['total'] ?? tickets.length,
          };
        }

        throw Exception('Format data tidak sesuai dari server.');
      } else {
        throw Exception('Gagal mengambil tiket: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getEventTickets: $e');
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  /// Ambil statistik total keseluruhan (total pembeli, hadir, belum hadir)
  Future<Map<String, dynamic>> getEventStatistics(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/tiket/event/$eventId/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Statistics Status: ${response.statusCode}');
      print('Statistics Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        if (jsonResponse is Map<String, dynamic>) {
          final data = jsonResponse['data'] ?? {};

          // Mapping field API ke field frontend
          final totalPembeli = data['total_tickets'] ?? 0;
          final totalHadir = data['checked_in'] ?? data['used_tickets'] ?? 0;
          final totalBelumHadir = data['not_checked_in'] ?? 0;

          return {
            'total_pembeli': totalPembeli,
            'total_hadir': totalHadir,
            'total_belum_hadir': totalBelumHadir,
          };
        }
      }

      throw Exception('Gagal memuat statistik event.');
    } catch (e) {
      print('Error in getEventStatistics: $e');
      return {
        'total_pembeli': 0,
        'total_hadir': 0,
        'total_belum_hadir': 0,
      };
    }
  }

  Future<Map<String, dynamic>> checkInTicket(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/tiket/check-in'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'qr_code': qrCode}),
      );

      print('Check-in Status: ${response.statusCode}');
      print('Check-in Body: ${response.body}');

      final dynamic jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return jsonResponse['data'];
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal check-in tiket');
      }
    } catch (e) {
      print('Error in checkInTicket: $e');
      throw Exception('Gagal check-in tiket: $e');
    }
  }
}
