import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:jagar/models/event_model.dart';

import 'package:jagar/services/auth_service.dart';
import 'package:jagar/services/panitia_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventProvider with ChangeNotifier {
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ✅ UPDATED: Fetch events yang ditugaskan ke panitia
  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ Gunakan PanitiaService untuk fetch assigned events
      _events = await PanitiaService.getMyAssignedEvents();
      
      print('✅ Fetched ${_events.length} assigned events');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching events: $e');
      
      _errorMessage = e.toString();
      _isLoading = false;
      
      // Check if it's 401 Unauthorized
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _errorMessage = 'Unauthorized: Please login again';
      }
      
      notifyListeners();
    }
  }

  /// ✅ Get event by ID
  Future<Event?> getEventById(int id) async {
    try {
      // Cek di cache dulu
      final cachedEvent = _events.firstWhere(
        (event) => event.idEvent == id,
        orElse: () => Event(idEvent: -1, namaEvent: ''),
      );
      
      if (cachedEvent.idEvent != -1) {
        return cachedEvent;
      }
      
      // Fetch from API
      return await PanitiaService.getEventDetail(id);
    } catch (e) {
      print('❌ Error getting event by ID: $e');
      return null;
    }
  }

  /// ✅ Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await ApiService.isAuthenticated();
  }

  /// ✅ Logout
  Future<void> logout() async {
    await ApiService.logout();
    _events = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ Refresh events
  Future<void> refreshEvents() async {
    await fetchEvents();
  }
}