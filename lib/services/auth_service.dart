import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User user = result.user!;

      // Create AppUser object
      AppUser appUser = AppUser(
        uid: user.uid,
        fullName: fullName,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        phoneNumber: phoneNumber,
        address: address,
        isActive: true,
      );

      // Save user data to Firestore
      await _db.collection('users').doc(user.uid).set(appUser.toMap());

      // Update display name
      await user.updateDisplayName(fullName);

      return appUser;
    } on FirebaseAuthException catch (e) {
      print('Registration Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Registration Error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User user = result.user!;

      // Update last login
      await _db.collection('users').doc(user.uid).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });

      // Get user data from Firestore
      AppUser appUser = await getUserData(user.uid);
      
      return appUser;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Login Error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<AppUser> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return AppUser.fromDocument(doc);
      } else {
        throw Exception('User data not found');
      }
    } catch (e) {
      print('Get User Data Error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      if (updates.isNotEmpty) {
        await _db.collection('users').doc(uid).update(updates);
        
        // Update Firebase Auth display name if changed
        if (fullName != null && currentUser != null) {
          await currentUser!.updateDisplayName(fullName);
        }
      }
    } catch (e) {
      print('Update Profile Error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Password Reset Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Password Reset Error: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      print('Change Password Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Change Password Error: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount(String currentPassword) async {
    try {
      User? user = currentUser;
      if (user == null) throw Exception('No user logged in');

      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Delete user data from Firestore
      await _db.collection('users').doc(user.uid).delete();
      
      // Delete user account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      print('Delete Account Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Delete Account Error: $e');
      rethrow;
    }
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('User Exists Check Error: $e');
      return false;
    }
  }

  // Get all users (admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('users').get();
      
      return querySnapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    } catch (e) {
      print('Get All Users Error: $e');
      rethrow;
    }
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _db.collection('users').doc(uid).update({'role': newRole});
    } catch (e) {
      print('Update User Role Error: $e');
      rethrow;
    }
  }

  // Activate/Deactivate user (admin only)
  Future<void> toggleUserStatus(String uid, bool isActive) async {
    try {
      await _db.collection('users').doc(uid).update({'isActive': isActive});
    } catch (e) {
      print('Toggle User Status Error: $e');
      rethrow;
    }
  }

  // Get users by role
  Future<List<AppUser>> getUsersByRole(String role) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: role)
          .get();
      
      return querySnapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    } catch (e) {
      print('Get Users By Role Error: $e');
      rethrow;
    }
  }
}
