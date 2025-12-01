import 'dart:convert';
import 'package:jagar/models/event_model.dart';
import 'package:jagar/services/api_config.dart';
import 'package:http/http.dart' as http;

class EventService {
  Future<List<Event>> getEvents() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.eventsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        
        // Handle berbagai format response
        List<dynamic> eventsJson;
        
        if (jsonData is List) {
          // Direct array response
          eventsJson = jsonData;
        } else if (jsonData is Map<String, dynamic>) {
          // Object with data/events key
          if (jsonData.containsKey('data')) {
            eventsJson = jsonData['data'] as List;
          } else if (jsonData.containsKey('events')) {
            eventsJson = jsonData['events'] as List;
          } else {
            eventsJson = [];
          }
        } else {
          eventsJson = [];
        }
        
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  Future<Event> getEventById(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.eventDetailEndpoint(id)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        
        // Handle berbagai format response
        if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('data')) {
            return Event.fromJson(jsonData['data']);
          } else if (jsonData.containsKey('event')) {
            return Event.fromJson(jsonData['event']);
          } else {
            return Event.fromJson(jsonData);
          }
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load event detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }
}