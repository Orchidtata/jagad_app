import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ Private constructor untuk singleton
  ApiService._();
  
  static const String baseUrl = 'http://172.18.216.143:8000/api';
  
  // ✅ FIXED: Get JWT token (not Firebase token)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Priority 1: Try JWT token
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null && jwtToken.isNotEmpty) {
      return jwtToken;
    }
    
    // Priority 2: Fallback to old token field (backward compatibility)
    return prefs.getString('token');
  }
  
  // ✅ FIXED: Save JWT token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwtToken', token);
    print('💾 JWT Token saved: ${token.substring(0, 20)}...');
  }
  
  // ✅ FIXED: Clear all auth tokens
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    await prefs.remove('token');
    await prefs.remove('firebaseToken');
    await prefs.remove('user');
    await prefs.remove('tokenExpiresAt');
    await prefs.remove('isAuthenticated');
    print('🗑 All tokens cleared');
  }
  
  // ✅ Get headers dengan JWT token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
  
  // ✅ FIXED: GET request with better error handling
  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    print('🔹 GET Request: $url');
    print('🔹 Headers: ${headers.keys.join(", ")}');
    
    try {
      final response = await http.get(url, headers: headers);
      
      print('🔹 Response Status: ${response.statusCode}');
      
      // Handle 401 Unauthorized (token expired)
      if (response.statusCode == 401) {
        print('❌ Token expired or invalid');
        await _handleUnauthorized();
      }
      
      if (response.statusCode != 200) {
        print('🔹 Response Body: ${response.body}');
      }
      
      return response;
    } catch (e) {
      print('❌ GET Request Error: $e');
      rethrow;
    }
  }
  
  // ✅ FIXED: POST request with better error handling
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    print('🔹 POST Request: $url');
    print('🔹 Body: $body');
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('🔹 Response Status: ${response.statusCode}');
      print('🔹 Response Body: ${response.body}');
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        print('❌ Token expired or invalid');
        await _handleUnauthorized();
      }
      
      return response;
    } catch (e) {
      print('❌ POST Request Error: $e');
      rethrow;
    }
  }
  
  // ✅ FIXED: PUT request with better error handling
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    print('🔹 PUT Request: $url');
    
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('🔹 PUT Status: ${response.statusCode}');
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        print('❌ Token expired or invalid');
        await _handleUnauthorized();
      }
      
      return response;
    } catch (e) {
      print('❌ PUT Request Error: $e');
      rethrow;
    }
  }
  
  // ✅ DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    print('🔹 DELETE Request: $url');
    
    try {
      final response = await http.delete(url, headers: headers);
      
      print('🔹 DELETE Status: ${response.statusCode}');
      
      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        print('❌ Token expired or invalid');
        await _handleUnauthorized();
      }
      
      return response;
    } catch (e) {
      print('❌ DELETE Request Error: $e');
      rethrow;
    }
  }
  
  // ✅ NEW: Verify JWT token
  static Future<bool> verifyToken() async {
    try {
      final token = await getToken();
      
      if (token == null || token.isEmpty) {
        return false;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ JWT token is valid');
        return true;
      }
      
      print('❌ JWT token is invalid');
      await clearToken();
      return false;
    } catch (e) {
      print('❌ Token verification error: $e');
      return false;
    }
  }
  
  // ✅ NEW: Refresh JWT token
  static Future<String?> refreshToken() async {
    try {
      final token = await getToken();
      
      if (token == null || token.isEmpty) {
        return null;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        final newToken = data['data']['token'];
        await saveToken(newToken);
        print('✅ JWT token refreshed');
        return newToken;
      }
      
      print('❌ Token refresh failed');
      await clearToken();
      return null;
    } catch (e) {
      print('❌ Token refresh error: $e');
      await clearToken();
      return null;
    }
  }
  
  // ✅ NEW: Logout from backend
  static Future<bool> logout() async {
    try {
      final token = await getToken();
      
      if (token != null && token.isNotEmpty) {
        // Call backend logout endpoint
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        print('✅ Backend logout successful');
      }
      
      // Clear local storage
      await clearToken();
      return true;
    } catch (e) {
      print('❌ Logout error: $e');
      // Force clear even if error
      await clearToken();
      return false;
    }
  }
  
  // ✅ Check if authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // ✅ NEW: Get current user from backend
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await get('/auth/me');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }
  
  // ✅ PRIVATE: Handle unauthorized (401) response
  static Future<void> _handleUnauthorized() async {
    // Try to refresh token first
    final newToken = await refreshToken();
    
    if (newToken == null) {
      // Refresh failed, clear all tokens
      await clearToken();
      // Note: Navigation to login should be handled by the app
      // You might want to use a stream or callback here
    }
  }
}