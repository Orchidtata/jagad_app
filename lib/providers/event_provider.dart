import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jagar/models/event_model.dart';
import 'package:jagar/services/event_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jagar/services/api_config.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ✅ Helper: Get token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwtToken');
  }

  /// ✅ Helper: Get headers dengan Authorization Bearer
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    
    print('🔑 Token from SharedPreferences: ${token?.substring(0, 20)}...');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// ✅ Fetch Events dengan Token di Header
  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConfig.baseUrl}/api/events');

      print('🔹 Fetching events from: $url');
      print('🔹 Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('🔹 Response Status: ${response.statusCode}');
      print('🔹 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> eventList = data['data'] ?? [];
          _events = eventList.map((json) => Event.fromJson(json)).toList();
          _errorMessage = null;
          
          print('✅ Events loaded: ${_events.length} events');
        } else {
          _errorMessage = data['message'] ?? 'Failed to load events';
          print('❌ API returned success=false: $_errorMessage');
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Unauthorized - Please login again';
        print('❌ 401 Unauthorized - Token invalid or expired');
        
        // Clear token dan redirect ke login
        await _clearToken();
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
        print('❌ Server error: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('❌ Exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Event?> fetchEventById(int id) async {
    try {
      return await _eventService.getEventById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// ✅ Clear token dari SharedPreferences
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    await prefs.remove('user');
    print('🗑 Token cleared from SharedPreferences');
  }

  /// ✅ Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  /// ✅ Logout (clear token)
  Future<void> logout() async {
    await _clearToken();
    _events = [];
    _errorMessage = null;
    notifyListeners();
  }
}