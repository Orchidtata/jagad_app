import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jagar/providers/event_provider.dart';
import 'package:jagar/screens/activity_history_screen.dart';
import 'package:jagar/screens/event_buyers_screen.dart';
import 'package:jagar/screens/login_screen.dart';
import 'package:jagar/screens/profile_screen.dart';
import 'package:jagar/services/api_config.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // ✅ Gunakan addPostFrameCallback untuk hindari context issue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  /// ✅ Initialize screen dengan check auth + fetch events
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    // Check if authenticated
    final isAuth = await eventProvider.isAuthenticated();

    print('🔐 Is Authenticated: $isAuth');

    if (!isAuth) {
      // Tidak ada token, redirect ke login
      print('❌ No token found, redirecting to login...');
      if (mounted) {
        _navigateToLogin();
      }
      return;
    }

    // Fetch events
    print('📡 Fetching events...');
    await eventProvider.fetchEvents();

    // Check if error 401 setelah fetch
    if (mounted &&
        eventProvider.errorMessage != null &&
        eventProvider.errorMessage!.contains('Unauthorized')) {
      print('❌ 401 Unauthorized detected, showing dialog...');
      _showUnauthorizedDialog();
    }
  }

  /// ✅ Navigate ke login screen
  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  /// ✅ Show dialog untuk 401 error
  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _logout(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B0000),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF7B0000),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo_badung.jpg',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.white,
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Jagad Badung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF7B0000)),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.history, color: Color(0xFF7B0000)),
            //   title: const Text('History Scan'),
            //   onTap: () {
            //     Navigator.pop(context); // Tutup drawer
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const ScanHistoryPage(),
            //       ),
            //     );
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF7B0000)),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Image.asset(
              'assets/logo_badung.jpg',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 40,
                  height: 40,
                  color: Colors.grey,
                  child: const Icon(Icons.image_not_supported, size: 20),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'JAGAD BADUNG',
              style: TextStyle(
                color: Color(0xFF7B0000),
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF7B0000),
              height: 8,
            ),
            Expanded(
              child: Consumer<EventProvider>(
                builder: (context, provider, _) {
                  // ✅ Loading state
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  // ✅ Error state (tapi bukan 401)
                  if (provider.errorMessage != null) {
                    // Jika 401, show loading karena dialog sudah muncul
                    if (provider.errorMessage!.contains('Unauthorized')) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    return _buildErrorState(provider);
                  }

                  // ✅ Empty state
                  if (provider.events.isEmpty) {
                    return _buildEmptyState(provider);
                  }

                  // ✅ Success state - show events
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchEvents(),
                    color: const Color(0xFF7B0000),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: provider.events.length,
                      itemBuilder: (context, index) {
                        final event = provider.events[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventBuyersScreen(
                                  eventId: event.idEvent,
                                  eventName: event.namaEvent,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildEventCard(event),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Fungsi logout dengan clear token
  /// ✅ FIXED: Logout dengan clear Google Sign-In
  Future<void> _logout(BuildContext context) async {
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      // 1. Logout dari backend
      await eventProvider.logout();

      // 2. Sign out dari Google
      await GoogleSignIn().signOut();

      // 3. Sign out dari Firebase
      await FirebaseAuth.instance.signOut();

      // 4. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('✅ Logout successful (Google + Firebase + Backend)');

      // Navigate ke login
      if (mounted) {
        _navigateToLogin();
      }
    } catch (e) {
      print('❌ Logout error: $e');
      // Tetap navigate ke login meskipun ada error
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  /// 🧱 Error State Widget
  Widget _buildErrorState(EventProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              "Gagal Memuat Data",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Unknown error',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchEvents(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7B0000),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧱 Empty State Widget
  Widget _buildEmptyState(EventProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              "Tidak Ada Event",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Belum ada event yang tersedia saat ini",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchEvents(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7B0000),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧱 Event Card Widget
  Widget _buildEventCard(dynamic event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Event Image
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildImage(event.banner),
          ),
          const SizedBox(width: 12),

          // Event Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.namaEvent ?? 'No Title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF7B0000),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Hari & Tanggal:",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.startTime != null
                      ? "${event.startTime!.day} ${_bulan(event.startTime!.month)} ${event.startTime!.year}"
                      : "-",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                if (event.lokasi != null && event.lokasi!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.lokasi!,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Arrow Icon
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF7B0000),
            size: 20,
          ),
        ],
      ),
    );
  }

  /// 🗓 Helper: Convert month number to Indonesian name
  String _bulan(int bulan) {
    const namaBulan = [
      "",
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember"
    ];
    return bulan >= 1 && bulan <= 12 ? namaBulan[bulan] : "";
  }

  /// 🖼 Helper: Build event image
  Widget _buildImage(String? banner) {
    const double width = 110;
    const double height = 80;

    // Fallback image
    Widget fallbackImage = Image.asset(
      "assets/event1.jpg",
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image, color: Colors.grey),
        );
      },
    );

    if (banner == null || banner.isEmpty) {
      return fallbackImage;
    }

    if (banner.startsWith("http")) {
      return Image.network(
        banner,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallbackImage,
      );
    }

    return Image.network(
      "${ApiConfig.baseUrl}/storage/$banner",
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => fallbackImage,
    );
  }
}
