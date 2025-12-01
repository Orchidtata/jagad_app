import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jagar/models/scanHistory_model.dart';
import 'package:jagar/services/auth_service.dart';

class ScanHistoryProvider extends ChangeNotifier {
  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<ScanHistory> _scanHistories = [];
  ScanHistory? _currentScanHistory;
  Map<String, dynamic>? _statistics;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ScanHistory> get scanHistories => _scanHistories;
  ScanHistory? get currentScanHistory => _currentScanHistory;
  Map<String, dynamic>? get statistics => _statistics;

  // Setter untuk loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Setter untuk error
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Scan Tiket
  Future<Map<String, dynamic>> scanTiket({
    required int idTiket,
    required int idUser,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.post(
        '/scan-history',
        {
          'id_tiket': idTiket,
          'id_user': idUser,
          'scan_time': DateTime.now().toIso8601String(),
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Berhasil scan
        if (data['data'] != null) {
          _currentScanHistory = ScanHistory.fromJson(data['data']);
        }

        _setLoading(false);
        return {
          'success': true,
          'message': data['message'] ?? 'Tiket berhasil di-scan',
          'data': data['data'],
        };
      } else if (response.statusCode == 409) {
        // Tiket sudah pernah di-scan
        _setError('Tiket sudah pernah di-scan sebelumnya!');
        _setLoading(false);

        return {
          'success': false,
          'message':
              data['message'] ?? 'Tiket sudah pernah di-scan sebelumnya!',
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        // Tiket tidak ditemukan
        _setError('Tiket tidak ditemukan');
        _setLoading(false);

        return {
          'success': false,
          'message': data['message'] ?? 'Tiket tidak ditemukan',
          'data': null,
        };
      } else if (response.statusCode == 400) {
        // Status tiket tidak valid
        _setError(data['message'] ?? 'Status tiket tidak valid');
        _setLoading(false);

        return {
          'success': false,
          'message': data['message'] ?? 'Status tiket tidak valid',
          'data': null,
        };
      } else {
        // Error lainnya
        _setError(data['message'] ?? 'Gagal melakukan scan tiket');
        _setLoading(false);

        return {
          'success': false,
          'message': data['message'] ?? 'Gagal melakukan scan tiket',
          'data': null,
        };
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);

      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Cek apakah tiket sudah pernah di-scan
  Future<Map<String, dynamic>> checkTiketScan(int idTiket) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.get('/scan-history/check/$idTiket');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        bool sudahScan = data['sudah_scan'] ?? false;

        if (data['data'] != null) {
          _currentScanHistory = ScanHistory.fromJson(data['data']);
        } else {
          _currentScanHistory = null;
        }

        _setLoading(false);
        return {
          'success': true,
          'sudah_scan': sudahScan,
          'message': data['message'],
          'data': _currentScanHistory,
        };
      } else {
        _setError('Gagal mengecek status scan tiket');
        _setLoading(false);

        return {
          'success': false,
          'sudah_scan': false,
          'data': null,
        };
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);

      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'sudah_scan': false,
      };
    }
  }

  /// Get scan history by event
  Future<bool> getScanHistoryByEvent(int eventId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.get('/scan-history/event/$eventId');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _scanHistories.clear();

        if (data['data'] != null && data['data'] is List) {
          for (var item in data['data']) {
            _scanHistories.add(ScanHistory.fromJson(item));
          }
        }

        _setLoading(false);
        return true;
      } else {
        _setError('Gagal memuat riwayat scan event');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get scan history by tiket
  Future<bool> getScanHistoryByTiket(int idTiket) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.get('/scan-history/tiket/$idTiket');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['data'] != null) {
          _currentScanHistory = ScanHistory.fromJson(data['data']);
        }
        _setLoading(false);
        return true;
      } else if (response.statusCode == 404) {
        _setError('Scan history tidak ditemukan');
        _currentScanHistory = null;
        _setLoading(false);
        return false;
      } else {
        _setError('Gagal memuat scan history');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get all scan history by user (petugas)
  Future<bool> getScanHistoryByUser(int idUser) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.get('/scan-history/user/$idUser');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _scanHistories.clear();

        if (data['data'] != null && data['data'] is List) {
          for (var item in data['data']) {
            _scanHistories.add(ScanHistory.fromJson(item));
          }
        }

        _setLoading(false);
        return true;
      } else {
        _setError('Gagal memuat riwayat scan');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get all scan history dengan pagination
  Future<bool> getAllScanHistory({int page = 1, int limit = 20}) async {
    _setLoading(true);
    _setError(null);

    try {
      final response =
          await ApiService.get('/scan-history?page=$page&limit=$limit');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Clear list jika page = 1, append jika page > 1
        if (page == 1) {
          _scanHistories.clear();
        }

        if (data['data'] != null && data['data'] is List) {
          for (var item in data['data']) {
            _scanHistories.add(ScanHistory.fromJson(item));
          }
        }

        _setLoading(false);
        return true;
      } else {
        _setError('Gagal memuat daftar scan history');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Get scan statistics
  Future<bool> getStatistics() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.get('/scan-history/statistics');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _statistics = data['data'];
        _setLoading(false);
        return true;
      } else {
        _setError('Gagal memuat statistik');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete scan history (untuk admin)
  Future<bool> deleteScanHistory(int idScan) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await ApiService.delete('/scan-history/$idScan');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Remove from local list
        _scanHistories.removeWhere((item) => item.idScan == idScan);
        _setLoading(false);
        return true;
      } else if (response.statusCode == 404) {
        _setError('Scan history tidak ditemukan');
        _setLoading(false);
        return false;
      } else {
        _setError(data['message'] ?? 'Gagal menghapus scan history');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Clear all data
  void clearData() {
    _scanHistories.clear();
    _currentScanHistory = null;
    _statistics = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh data
  Future<void> refresh() async {
    await getAllScanHistory(page: 1, limit: 20);
  }
}
