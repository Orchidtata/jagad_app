import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jagar/models/event_model.dart';
import 'package:jagar/services/auth_service.dart';

class PanitiaService {
  static const String baseUrl = 'http://172.18.210.102:8000/api';

  /// ✅ Check apakah user memiliki akses sebagai Panitia
  static Future<Map<String, dynamic>> checkPanitiaAccess() async {
    try {
      final response = await ApiService.get('/check-panitia-access');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'has_panitia_role': data['data']['has_panitia_role'] ?? false,
            'has_assigned_events': data['data']['has_assigned_events'] ?? false,
            'can_access': data['data']['can_access_panitia_page'] ?? false,
            'assigned_events_count': data['data']['assigned_events_count'] ?? 0,
            'user': data['data']['user'],
          };
        }
      }
      
      return {
        'success': false,
        'has_panitia_role': false,
        'has_assigned_events': false,
        'can_access': false,
        'assigned_events_count': 0,
        'message': 'Failed to check access',
      };
    } catch (e) {
      print('❌ Error checking panitia access: $e');
      return {
        'success': false,
        'has_panitia_role': false,
        'has_assigned_events': false,
        'can_access': false,
        'assigned_events_count': 0,
        'message': e.toString(),
      };
    }
  }

  /// ✅ Get event yang di-assign ke panitia
  static Future<List<Event>> getMyAssignedEvents() async {
    try {
      final response = await ApiService.get('/events/my-assigned');
      
      print('🔹 Response Status: ${response.statusCode}');
      print('🔹 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final eventsData = data['data']['events'] as List;
          return eventsData.map((json) => Event.fromJson(json)).toList();
        }
      }
      
      throw Exception('Failed to load assigned events');
    } catch (e) {
      print('❌ Error fetching assigned events: $e');
      rethrow;
    }
  }

  /// ✅ Get detail event (untuk panitia)
  static Future<Event?> getEventDetail(int eventId) async {
    try {
      final response = await ApiService.get('/events/$eventId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return Event.fromJson(data['data']);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error fetching event detail: $e');
      return null;
    }
  }
}