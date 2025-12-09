import 'package:flutter/material.dart';
import 'package:jagar/models/user_model.dart';
import 'package:jagar/providers/auth_provider.dart';
import 'package:jagar/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  // 🎨 Maroon Color Scheme
  static const Color maroonPrimary = Color(0xFF800020); // Deep Maroon
  static const Color maroonLight = Color(0xFF9B2847); // Light Maroon
  static const Color maroonDark = Color(0xFF5C0015); // Dark Maroon
  static const Color maroonAccent = Color(0xFFD4516D); // Accent

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          if (user == null) {
            return const Center(
              child: Text('User tidak ditemukan'),
            );
          }

          return CustomScrollView(
            slivers: [
              // Custom AppBar with Maroon Gradient
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: maroonPrimary,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    tooltip: 'Edit Profil',
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          maroonDark,
                          maroonPrimary,
                          maroonLight,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 80, bottom: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Profile Photo with Maroon Border
                              _buildProfilePhoto(context, user),
                              const SizedBox(height: 12),
                              // Name
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  user.nama,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Email
                              if (user.email != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    user.email!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              // Role Chips with Maroon Theme
                              if (user.roles.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.center,
                                    children: user.roles.map((role) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          role,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Information Section
                      _buildSection(
                        context,
                        title: 'Informasi Pribadi',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            subtitle: user.email ?? 'Tidak ada',
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.phone_outlined,
                            title: 'Nomor Telepon',
                            subtitle: user.phone ?? 'Tidak ada',
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.verified_user_outlined,
                            title: 'Status Akun',
                            subtitle: user.status == 'active' ? 'Aktif' : 'Tidak Aktif',
                            subtitleColor: user.status == 'active' 
                                ? Colors.green 
                                : Colors.red,
                          ),
                        ],
                      ),

                      // const SizedBox(height: 16),

                      // // Account Settings Section
                      // _buildSection(
                      //   context,
                      //   title: 'Pengaturan Akun',
                      //   icon: Icons.settings_outlined,
                      //   children: [
                      //     _buildActionTile(
                      //       icon: Icons.lock_outline,
                      //       iconColor: maroonPrimary,
                      //       title: 'Ubah Password',
                      //       onTap: () => _showChangePasswordDialog(context),
                      //     ),
                      //     _buildDivider(),
                      //     _buildActionTile(
                      //       icon: Icons.notifications_outlined,
                      //       iconColor: maroonPrimary,
                      //       title: 'Notifikasi',
                      //       onTap: () {},
                      //     ),
                      //     _buildDivider(),
                      //     _buildActionTile(
                      //       icon: Icons.security_outlined,
                      //       iconColor: maroonPrimary,
                      //       title: 'Keamanan & Privasi',
                      //       onTap: () {},
                      //     ),
                      //   ],
                      // ),

                      // const SizedBox(height: 16),

                      // // Admin Section (if user is admin)
                      // if (user.isAdmin)
                      //   _buildSection(
                      //     context,
                      //     title: 'Admin',
                      //     icon: Icons.admin_panel_settings_outlined,
                      //     children: [
                      //       _buildActionTile(
                      //         icon: Icons.dashboard_outlined,
                      //         iconColor: maroonPrimary,
                      //         title: 'Dashboard Admin',
                      //         onTap: () {},
                      //       ),
                      //       _buildDivider(),
                      //       _buildActionTile(
                      //         icon: Icons.people_outline,
                      //         iconColor: maroonPrimary,
                      //         title: 'Kelola Pengguna',
                      //         onTap: () {},
                      //       ),
                      //     ],
                      //   ),

                      // if (user.isAdmin) const SizedBox(height: 16),

                      // // About Section
                      // _buildSection(
                      //   context,
                      //   title: 'Lainnya',
                      //   icon: Icons.info_outline,
                      //   children: [
                      //     _buildActionTile(
                      //       icon: Icons.help_outline,
                      //       iconColor: maroonPrimary,
                      //       title: 'Bantuan & Dukungan',
                      //       onTap: () {},
                      //     ),
                      //     _buildDivider(),
                      //     _buildActionTile(
                      //       icon: Icons.info_outline,
                      //       iconColor: maroonPrimary,
                      //       title: 'Tentang Aplikasi',
                      //       onTap: () => _showAboutDialog(context),
                      //     ),
                      //     _buildDivider(),
                      //     _buildActionTile(
                      //       icon: Icons.policy_outlined,
                      //       iconColor: maroonPrimary,
                      //       title: 'Kebijakan Privasi',
                      //       onTap: () {},
                      //     ),
                      //   ],
                      // ),

                      // const SizedBox(height: 24),

                      // // Logout Button with Maroon Theme
                      // Container(
                      //   decoration: BoxDecoration(
                      //     gradient: const LinearGradient(
                      //       colors: [maroonDark, maroonPrimary],
                      //     ),
                      //     borderRadius: BorderRadius.circular(12),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: maroonPrimary.withOpacity(0.3),
                      //         blurRadius: 8,
                      //         offset: const Offset(0, 4),
                      //       ),
                      //     ],
                      //   ),
                      //   child: Material(
                      //     color: Colors.transparent,
                      //     child: InkWell(
                      //       onTap: () => _handleLogout(context),
                      //       borderRadius: BorderRadius.circular(12),
                      //       child: Container(
                      //         padding: const EdgeInsets.symmetric(vertical: 16),
                      //         child: const Row(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             Icon(Icons.logout, color: Colors.white),
                      //             SizedBox(width: 8),
                      //             Text(
                      //               'Keluar',
                      //               style: TextStyle(
                      //                 fontSize: 16,
                      //                 fontWeight: FontWeight.bold,
                      //                 color: Colors.white,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfilePhoto(BuildContext context, User user) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              child: user.getPhotoUrl() != null
                  ? ClipOval(
                      child: Image.network(
                        user.getPhotoUrl()!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitialsAvatar(user);
                        },
                      ),
                    )
                  : _buildInitialsAvatar(user),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [maroonDark, maroonPrimary],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(User user) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            maroonLight.withOpacity(0.3),
            maroonPrimary.withOpacity(0.3),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.getInitials(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: maroonPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        maroonPrimary.withOpacity(0.1),
                        maroonLight.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: maroonPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: maroonPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: maroonPrimary),
            SizedBox(width: 12),
            Text('Keluar'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: maroonPrimary),
                ),
              );

              // Logout
              await context.read<AuthProvider>().logout();
              
              // Navigate to login screen
              if (context.mounted) {
                Navigator.of(context).pop(); // Close loading
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: maroonPrimary),
            SizedBox(width: 12),
            Text('Ubah Password'),
          ],
        ),
        content: const Text(
          'Fitur ubah password belum tersedia.\n\nAnda dapat menggunakan fitur "Lupa Password" di halaman login.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: maroonPrimary),
            SizedBox(width: 12),
            Text('Tentang Aplikasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FlutterLogo(size: 48),
            const SizedBox(height: 16),
            const Text(
              'Pemkab Badung',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: maroonPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Versi 1.0.0'),
            const SizedBox(height: 16),
            const Text('Aplikasi manajemen event untuk Pemkab Badung.'),
            const SizedBox(height: 8),
            Text(
              '© 2024 Pemkab Badung. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}