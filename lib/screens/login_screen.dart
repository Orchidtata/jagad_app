import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    _checkLoginStatus();
  }

  // ✅ FIXED: Check JWT token validity
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    
    if (jwtToken != null && jwtToken.isNotEmpty) {
      // Verify JWT token with backend
      try {
        final response = await http.post(
          Uri.parse('http://172.18.216.143:8000/api/auth/verify-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          // Token valid, navigate to home
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          // Token invalid, clear storage
          await prefs.remove('jwtToken');
          await prefs.remove('firebaseToken');
          await prefs.remove('user');
        }
      } catch (e) {
        print('❌ Token verification error: $e');
        // Clear invalid token
        await prefs.remove('jwtToken');
        await prefs.remove('firebaseToken');
        await prefs.remove('user');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _namaController.dispose();
    _nipController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Sign in with Google and get JWT token
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Google Sign In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 2. Firebase Authentication
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 3. Get Firebase ID Token
      final firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        throw Exception('Firebase token tidak ditemukan');
      }

      print('🔑 Firebase token obtained: ${firebaseToken.substring(0, 30)}...');

      // 4. Send Firebase token to backend to get JWT
      final response = await http.post(
        Uri.parse('http://172.18.216.143:8000/api/auth/firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': firebaseToken}),
      );

      print('🔹 Backend response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // ✅ FIXED: Save JWT token (not Firebase token)
        final prefs = await SharedPreferences.getInstance();
        
        final jwtToken = data['data']['token']; // 🔑 JWT Token from backend
        final userData = data['data']['user'];
        final tokenExpiresAt = data['data']['expires_at'];

        // Save JWT token
        await prefs.setString('jwtToken', jwtToken);
        await prefs.setString('firebaseToken', firebaseToken); // Keep for reference
        await prefs.setString('user', jsonEncode(userData));
        await prefs.setString('tokenExpiresAt', tokenExpiresAt);
        await prefs.setBool('isAuthenticated', true);

        print('✅ JWT token saved');
        print('👤 User: ${userData['nama']}');
        print('🎭 Roles: ${userData['roles']}');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal login Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Manual login (for testing - should use backend API in production)
  void _manualLogin() async {
    if (_namaController.text.isEmpty || _nipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan NIP harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Call backend login API
      // For now, save dummy data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode({
        'nama': _namaController.text,
        'nip': _nipController.text,
      }));
      await prefs.setBool('isAuthenticated', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B0000),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/logo_badung.jpg',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'JAGAD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    'BADUNG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 151, 101, 101)
                              .withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/bupati.png',
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'WELCOME!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              TextField(
                controller: _namaController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person, color: Colors.black54),
                  hintText: 'Nama',
                  hintStyle: const TextStyle(color: Colors.black45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nipController,
                obscureText: _obscureText,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                  hintText: 'NIP',
                  hintStyle: const TextStyle(color: Colors.black45),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _manualLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A0000),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black45,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                icon: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Image.asset(
                        'assets/logo_google.png',
                        height: 24,
                      ),
                label: Text(
                  _isLoading ? 'Memproses...' : 'Login dengan Google',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}