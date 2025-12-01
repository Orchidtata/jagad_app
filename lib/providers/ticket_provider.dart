import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jagar/models/ticket_model.dart';
import 'package:jagar/services/auth_service.dart';

class TicketProvider with ChangeNotifier {
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  // Statistics
  int _totalTickets = 0;
  int _totalHadir = 0;
  int _totalBelumHadir = 0;
  double _checkInPercentage = 0.0;
  Map<String, dynamic>? _statistics;

  // Getters
  List<Ticket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get total => _total;
  int get totalTickets => _totalTickets;
  int get totalHadir => _totalHadir;
  int get totalBelumHadir => _totalBelumHadir;
  double get checkInPercentage => _checkInPercentage;
  Map<String, dynamic>? get statistics => _statistics;

  // Filtered lists
  List<Ticket> get hadirTickets =>
      _tickets.where((t) => t.kehadiran == 'hadir').toList();

  List<Ticket> get belumHadirTickets =>
      _tickets.where((t) => t.kehadiran == 'belum_hadir').toList();

  /// ✅ Fetch Event Tickets dengan Token di Header
  /// Sesuai dengan TicketController: getEventTickets()
  Future<void> fetchEventTickets(int eventId, {int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ Endpoint sesuai backend: GET /api/tiket/event/{eventId}
      final response = await ApiService.get(
        '/tiket/event/$eventId?page=$page&per_page=50',
      );

      print('📡 Tickets Response Status: ${response.statusCode}');
      print('📡 Tickets Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          final data = jsonData['data'];

          // ✅ Parse pagination data dari Laravel paginate()
          if (data is Map && data.containsKey('data')) {
            // Laravel pagination format
            final ticketsData = data['data'] as List;
            _tickets = ticketsData.map((json) => Ticket.fromJson(json)).toList();
            
            _currentPage = data['current_page'] ?? 1;
            _lastPage = data['last_page'] ?? 1;
            _total = data['total'] ?? 0;
          } else if (data is List) {
            // Direct array
            _tickets = data.map((json) => Ticket.fromJson(json)).toList();
            _currentPage = 1;
            _lastPage = 1;
            _total = _tickets.length;
          }

          // ✅ Urutkan: Hadir di atas, belum hadir di bawah
          _tickets.sort((a, b) {
            if (a.kehadiran == 'hadir' && b.kehadiran != 'hadir') return -1;
            if (a.kehadiran != 'hadir' && b.kehadiran == 'hadir') return 1;
            return 0;
          });

          _errorMessage = null;
          print('✅ Tickets loaded: ${_tickets.length} tickets');
        } else {
          _errorMessage = jsonData['message'] ?? 'Failed to load tickets';
          print('❌ API Error: $_errorMessage');
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Unauthorized - Please login again';
        print('❌ 401 Unauthorized');
      } else if (response.statusCode == 403) {
        _errorMessage = 'You do not have access to this event';
        print('❌ 403 Forbidden');
      } else if (response.statusCode == 404) {
        _errorMessage = 'Event tickets not found';
        print('❌ 404 Not Found');
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
        print('❌ Server error: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      print('❌ Exception in fetchEventTickets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Fetch Event Statistics dengan Token di Header
  /// Sesuai dengan TicketController: getEventStatistics()
  Future<void> fetchEventStatistics(int eventId) async {
    try {
      // ✅ Endpoint sesuai backend: GET /api/tiket/event/{eventId}/statistics
      final response = await ApiService.get(
        '/tiket/event/$eventId/statistics',
      );

      print('📊 Statistics Response Status: ${response.statusCode}');
      print('📊 Statistics Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          final data = jsonData['data'];
          _statistics = data;

          // ✅ Map sesuai response backend
          _totalTickets = data['total_tickets'] ?? 0;
          _totalHadir = data['checked_in'] ?? 0; // checked_in dari backend
          _totalBelumHadir = data['not_checked_in'] ?? 0; // not_checked_in dari backend
          _checkInPercentage = (data['check_in_percentage'] ?? 0.0).toDouble();

          print('✅ Statistics loaded: Total=$_totalTickets, Hadir=$_totalHadir, Belum=$_totalBelumHadir');
          notifyListeners();
        } else {
          print('❌ Statistics API Error: ${jsonData['message']}');
        }
      } else if (response.statusCode == 401) {
        print('❌ Statistics 401 Unauthorized');
      } else if (response.statusCode == 403) {
        print('❌ Statistics 403 Forbidden');
      } else if (response.statusCode == 404) {
        print('❌ Statistics 404 Not Found');
      } else {
        print('❌ Statistics Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchEventStatistics: $e');
    }
  }

  /// ✅ Scan Ticket (Check-in)
  /// Sesuai dengan TicketController: scan()
  Future<Map<String, dynamic>> scanTicket(String qrCode) async {
    try {
      // ✅ Endpoint sesuai backend: POST /api/tiket/scan
      final response = await ApiService.post('/tiket/scan', {
        'qr_code': qrCode,
      });

      print('🔍 Scan Response Status: ${response.statusCode}');
      print('🔍 Scan Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Check-in successful');
        return {
          'success': true,
          'message': data['message'] ?? 'Check-in berhasil!',
          'data': data['data'],
        };
      } else {
        print('❌ Check-in failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Check-in gagal',
        };
      }
    } catch (e) {
      print('❌ Exception in scanTicket: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// ✅ Validate Ticket (Check before scan)
  /// Sesuai dengan TicketController: validateTicket()
  Future<Map<String, dynamic>> validateTicket(String qrCode) async {
    try {
      // ✅ Endpoint sesuai backend: POST /api/tiket/validate
      final response = await ApiService.post('/tiket/validate', {
        'qr_code': qrCode,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Tiket valid',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Tiket tidak valid',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// ✅ Get My Tickets (current user)
  /// Sesuai dengan TicketController: myTickets()
  Future<void> fetchMyTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ Endpoint sesuai backend: GET /api/tiket/my-tickets
      final response = await ApiService.get('/tiket/my-tickets');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['success'] == true) {
          final ticketsData = jsonData['data'] as List;
          _tickets = ticketsData.map((json) => Ticket.fromJson(json)).toList();
          _errorMessage = null;
          print('✅ My tickets loaded: ${_tickets.length}');
        } else {
          _errorMessage = jsonData['message'] ?? 'Failed to load tickets';
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Unauthorized - Please login again';
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      print('❌ Exception in fetchMyTickets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clearData() {
    _tickets = [];
    _totalTickets = 0;
    _totalHadir = 0;
    _totalBelumHadir = 0;
    _checkInPercentage = 0.0;
    _statistics = null;
    _errorMessage = null;
    _currentPage = 1;
    _lastPage = 1;
    _total = 0;
    notifyListeners();
  }
}