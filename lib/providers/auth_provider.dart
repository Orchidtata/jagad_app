import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jagar/models/user_model.dart';
import 'package:jagar/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

// Import your existing models and services
// import 'models/user.dart';
// import 'services/api_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _errorMessage;
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;

  // Constructor
  AuthProvider() {
    _initAuth();
  }

  // ✅ Initialize auth state on app start
  Future<void> _initAuth() async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      // Check if JWT token exists
      final hasValidToken = await ApiService.isAuthenticated();
      
      if (hasValidToken) {
        // Verify token and get user data
        final isValid = await ApiService.verifyToken();
        
        if (isValid) {
          await _loadUserData();
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
          await ApiService.clearToken();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('❌ Init auth error: $e');
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  // ✅ Load user data from backend
  Future<void> _loadUserData() async {
    try {
      final userData = await ApiService.getCurrentUser();
      
      if (userData != null) {
        _user = User.fromJson(userData);
        
        // Save user to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userData));
        
        print('✅ User data loaded: ${_user?.nama}');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // ✅ Firebase Authentication
  Future<bool> loginWithFirebase(String firebaseToken) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final response = await ApiService.post(
        '/auth/firebase',
        {'firebase_token': firebaseToken},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save JWT token
        final jwtToken = data['data']['token'];
        await ApiService.saveToken(jwtToken);

        // Parse and save user data
        _user = User.fromJson(data['data']['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['data']['user']));

        _status = AuthStatus.authenticated;
        notifyListeners();
        
        print('✅ Firebase login successful');
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Login gagal';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Firebase login error: $e');
      _errorMessage = 'Terjadi kesalahan saat login';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ✅ Email/Password Login
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final response = await ApiService.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save JWT token
        final jwtToken = data['data']['token'];
        await ApiService.saveToken(jwtToken);

        // Parse and save user data
        _user = User.fromJson(data['data']['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['data']['user']));

        _status = AuthStatus.authenticated;
        notifyListeners();
        
        print('✅ Email login successful');
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Email atau password salah';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Email login error: $e');
      _errorMessage = 'Terjadi kesalahan saat login';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ✅ Register
  Future<bool> register({
    required String nama,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final response = await ApiService.post(
        '/auth/register',
        {
          'nama': nama,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          if (phone != null) 'phone': phone,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Save JWT token
        final jwtToken = data['data']['token'];
        await ApiService.saveToken(jwtToken);

        // Parse and save user data
        _user = User.fromJson(data['data']['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(data['data']['user']));

        _status = AuthStatus.authenticated;
        notifyListeners();
        
        print('✅ Registration successful');
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Registrasi gagal';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      _errorMessage = 'Terjadi kesalahan saat registrasi';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ✅ Update Profile
  Future<bool> updateProfile({
    String? nama,
    String? phone,
    String? photo,
  }) async {
    try {
      final response = await ApiService.put(
        '/auth/profile',
        {
          if (nama != null) 'nama': nama,
          if (phone != null) 'phone': phone,
          if (photo != null) 'photo': photo,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update local user data
        _user = _user?.copyWith(
          nama: nama ?? _user?.nama,
          phone: phone ?? _user?.phone,
          photo: photo ?? _user?.photo,
        );

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));

        notifyListeners();
        
        print('✅ Profile updated');
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Update profile gagal';
        return false;
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      _errorMessage = 'Terjadi kesalahan saat update profile';
      return false;
    }
  }

  // ✅ Logout
  Future<void> logout() async {
    try {
      // Call backend logout
      await ApiService.logout();

      // Sign out from Firebase
      try {
        await _firebaseAuth.signOut();
      } catch (e) {
        print('⚠️ Firebase signout error: $e');
      }

      // Clear local data
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      
      notifyListeners();
      
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
      // Force logout locally even if backend fails
      await ApiService.clearToken();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // ✅ Refresh Token
  Future<bool> refreshToken() async {
    try {
      final newToken = await ApiService.refreshToken();
      
      if (newToken != null) {
        await _loadUserData();
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Refresh token error: $e');
      return false;
    }
  }

  // ✅ Check if user has specific role
  bool hasRole(String role) {
    return _user?.hasRole(role) ?? false;
  }

  // ✅ Check if user has specific permission
  bool hasPermission(String permission) {
    return _user?.hasPermission(permission) ?? false;
  }

  // ✅ Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}