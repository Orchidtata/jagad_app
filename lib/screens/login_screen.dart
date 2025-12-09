import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'package:jagar/services/panitia_service.dart';

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

    _initializeLoginScreen();
  }

  Future<void> _initializeLoginScreen() async {
    try {
      await GoogleSignIn().signOut();
      print('🔓 Google Sign-In cleared on init');
    } catch (e) {
      print('⚠ Error clearing Google Sign-In: $e');
    }

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');

    if (jwtToken != null && jwtToken.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('http://172.18.210.102:8000/api/auth/verify-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          // ✅ Token valid, cek role panitia
          await _checkPanitiaAccessAndNavigate();
        } else {
          await prefs.remove('jwtToken');
          await prefs.remove('firebaseToken');
          await prefs.remove('user');
        }
      } catch (e) {
        print('❌ Token verification error: $e');
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

  /// ✅ UPDATED: Check panitia access setelah login
  Future<void> _checkPanitiaAccessAndNavigate() async {
    try {
      final accessData = await PanitiaService.checkPanitiaAccess();
      
      if (accessData['success'] == true) {
        final hasPanitiaRole = accessData['has_panitia_role'] ?? false;
        final hasAssignedEvents = accessData['has_assigned_events'] ?? false;
        
        if (!hasPanitiaRole) {
          // ❌ Bukan role Panitia
          _showAccessDeniedDialog(
            'Akses Ditolak',
            'Hanya pengguna dengan role Panitia yang dapat mengakses aplikasi ini.',
          );
          await _clearAuthData();
          return;
        }
        
        if (!hasAssignedEvents) {
          // ❌ Panitia tapi belum ditugaskan ke event manapun
          _showAccessDeniedDialog(
            'Tidak Ada Penugasan',
            'Anda belum ditugaskan ke event manapun. Silakan hubungi administrator.',
          );
          await _clearAuthData();
          return;
        }
        
        // ✅ Role Panitia dan ada penugasan, navigate ke home
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        // Error checking access
        _showErrorDialog('Gagal memeriksa akses. Silakan coba lagi.');
        await _clearAuthData();
      }
    } catch (e) {
      print('❌ Error checking panitia access: $e');
      _showErrorDialog('Terjadi kesalahan. Silakan coba lagi.');
      await _clearAuthData();
    }
  }

  /// ✅ Clear auth data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    await prefs.remove('firebaseToken');
    await prefs.remove('user');
    await prefs.remove('isAuthenticated');
    
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  /// ✅ Show access denied dialog
  void _showAccessDeniedDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ✅ Show error dialog
  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ✅ UPDATED: Sign in dengan Google + check panitia access
  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();

      print('🔓 Previous sessions cleared');

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print('❌ User cancelled Google Sign-In');
        setState(() => _isLoading = false);
        return;
      }

      print('✅ Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        throw Exception('Firebase token tidak ditemukan');
      }

      print('🔑 Firebase token obtained');

      final response = await http.post(
        Uri.parse('http://172.18.210.102:8000/api/auth/firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': firebaseToken}),
      );

      print('🔹 Backend response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        final jwtToken = data['data']['token'];
        final userData = data['data']['user'];
        final tokenExpiresAt = data['data']['expires_at'];

        await prefs.setString('jwtToken', jwtToken);
        await prefs.setString('firebaseToken', firebaseToken);
        await prefs.setString('user', jsonEncode(userData));
        await prefs.setString('tokenExpiresAt', tokenExpiresAt);
        await prefs.setBool('isAuthenticated', true);

        print('✅ Login successful');
        print('👤 User: ${userData['nama']}');

        // ✅ Check panitia access before navigating
        await _checkPanitiaAccessAndNavigate();
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

  void _manualLogin() async {
    if (_namaController.text.isEmpty || _nipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan NIP harus diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user',
          jsonEncode({
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
                    'WELCOME PANITIA!',
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