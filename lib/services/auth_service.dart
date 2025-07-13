import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Original sign in method (for backward compatibility)
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('خطای غیرمنتظره در ورود: $e');
    }
  }

  // Updated login method with role detection
  Future<String?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User user = result.user!;
      
      // Get user document from Firestore
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Check if user is active
        bool isActive = userData['isActive'] ?? true;
        if (!isActive) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'حساب کاربری شما غیرفعال شده است',
          );
        }
        
        // Update last login time
        await _db.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        String role = userData['role'] ?? 'customer';
        return role;
      } else {
        // If user document doesn't exist, create it with default role
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'fullName': user.displayName ?? '',
          'role': 'customer',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        return 'customer';
      }
    } on FirebaseAuthException catch (e) {
      // Re-throw Firebase Auth exceptions to maintain error handling
      rethrow;
    } catch (e) {
      throw Exception('خطا در ورود: $e');
    }
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] as String?;
      }
      
      return null;
    } catch (e) {
      throw Exception('خطا در دریافت نقش کاربر: $e');
    }
  }

  // Get user data
  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return AppUser.fromMap(userData);
      }
      
      return null;
    } catch (e) {
      throw Exception('خطا در دریافت اطلاعات کاربر: $e');
    }
  }

  // Register new user
  Future<AppUser?> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User user = result.user!;
      
      // Update display name
      await user.updateDisplayName(fullName);
      
      // Create user document in Firestore
      AppUser newUser = AppUser(
        uid: user.uid,
        email: email,
        fullName: fullName,
        role: role,
        phoneNumber: phoneNumber,
        address: address,
        isActive: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      
      await _db.collection('users').doc(user.uid).set(newUser.toMap());
      
      return newUser;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('خطا در ثبت‌نام: $e');
    }
  }

  // Update user role (Admin only)
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _db.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطا در به‌روزرسانی نقش کاربر: $e');
    }
  }

  // Activate/Deactivate user (Admin only)
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('خطا در تغییر وضعیت کاربر: $e');
    }
  }

  // Get all users (Admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('users').get();
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return AppUser.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('خطا در دریافت لیست کاربران: $e');
    }
  }

  // Get users by role
  Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return AppUser.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('خطا در دریافت کاربران بر اساس نقش: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('خطا در خروج از حساب کاربری: $e');
    }
  }

  // Delete user account (Admin only)
  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document from Firestore
      await _db.collection('users').doc(uid).delete();
      
      // Note: Firebase Auth user deletion requires the user to be currently signed in
      // For admin deletion, you might need to use Firebase Admin SDK
    } catch (e) {
      throw Exception('خطا در حذف کاربر: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('خطا در ارسال ایمیل بازیابی رمز عبور: $e');
    }
  }

  // Check if user is admin
  Future<bool> isAdmin(String uid) async {
    try {
      String? role = await getUserRole(uid);
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Check if user is seller
  Future<bool> isSeller(String uid) async {
    try {
      String? role = await getUserRole(uid);
      return role == 'sales' || role == 'seller';
    } catch (e) {
      return false;
    }
  }
}
