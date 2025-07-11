import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isActive': isActive,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Create from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastLogin: map['lastLogin'] != null 
          ? (map['lastLogin'] as Timestamp).toDate() 
          : null,
      isActive: map['isActive'] ?? true,
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // Create from Firestore DocumentSnapshot
  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap(data);
  }

  // Copy with method for updates
  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // Check if user is admin
  bool get isAdmin => role == 'admin';
  
  // Check if user is customer
  bool get isCustomer => role == 'customer';
  
  // Check if user is sales person
  bool get isSales => role == 'sales';

  // Get display name
  String get displayName => fullName.isNotEmpty ? fullName : email;

  @override
  String toString() {
    return 'AppUser(uid: $uid, fullName: $fullName, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// User roles enum for better type safety
enum UserRole {
  admin('admin'),
  customer('customer'),
  sales('sales');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.value == role,
      orElse: () => UserRole.customer,
    );
  }
}
