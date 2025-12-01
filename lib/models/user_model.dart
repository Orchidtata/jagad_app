class User {
  final int idUser;
  final String nama;
  final String? email;
  final String? phone;
  final String? firebaseUid;
  final String? photo;
  final String status; // 'active', 'inactive'
  final List<String> roles; // ✅ NEW: User roles
  final List<String> permissions; // ✅ NEW: User permissions

  User({
    required this.idUser,
    required this.nama,
    this.email,
    this.phone,
    this.firebaseUid,
    this.photo,
    required this.status,
    this.roles = const [], // ✅ NEW
    this.permissions = const [], // ✅ NEW
  });

  // ✅ FIXED: Parse from JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: json['id_user'] ?? 0,
      nama: json['nama'] ?? '',
      email: json['email'],
      phone: json['phone'],
      firebaseUid: json['firebase_uid'],
      photo: json['photo'],
      status: json['status'] ?? 'active',
      // ✅ Parse roles array
      roles: json['roles'] != null 
          ? List<String>.from(json['roles']) 
          : [],
      // ✅ Parse permissions array
      permissions: json['permissions'] != null 
          ? List<String>.from(json['permissions']) 
          : [],
    );
  }

  // ✅ FIXED: Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nama': nama,
      'email': email,
      'phone': phone,
      'firebase_uid': firebaseUid,
      'photo': photo,
      'status': status,
      'roles': roles,
      'permissions': permissions,
    };
  }

  // ✅ NEW: Get full photo URL
  String? getPhotoUrl() {
    if (photo == null || photo!.isEmpty) return null;
    
    // If already full URL (from Google OAuth)
    if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
      return photo;
    }
    
    // If relative path from backend
    if (photo!.startsWith('/storage/')) {
      // Update this URL to match your backend
      const baseUrl = 'http://172.18.216.143:8000';
      return '$baseUrl$photo';
    }
    
    return photo;
  }

  // ✅ NEW: Check if user has specific role
  bool hasRole(String role) {
    return roles.contains(role);
  }

  // ✅ NEW: Check if user has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  // ✅ NEW: Check if user is admin
  bool get isAdmin {
    return hasRole('Admin') || hasRole('Super Admin');
  }

  // ✅ NEW: Get user initials (for avatar fallback)
  String getInitials() {
    if (nama.isEmpty) return '?';
    
    final words = nama.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    
    return (words[0][0] + words[words.length - 1][0]).toUpperCase();
  }

  // ✅ NEW: Copy with method (for state management)
  User copyWith({
    int? idUser,
    String? nama,
    String? email,
    String? phone,
    String? firebaseUid,
    String? photo,
    String? status,
    List<String>? roles,
    List<String>? permissions,
  }) {
    return User(
      idUser: idUser ?? this.idUser,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      photo: photo ?? this.photo,
      status: status ?? this.status,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  String toString() {
    return 'User(id: $idUser, nama: $nama, email: $email, roles: $roles)';
  }
}