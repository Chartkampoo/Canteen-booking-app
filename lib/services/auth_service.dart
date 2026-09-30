import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
    required String studentId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    final newUser = AppUser(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      studentId: studentId,
    );

    await _db
        .collection('users')
        .doc(credential.user!.uid)
        .set(newUser.toMap());

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<AppUser?> fetchProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(uid, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile(AppUser user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));

    if (_auth.currentUser != null && _auth.currentUser!.uid == user.uid) {
      await _auth.currentUser!.updateDisplayName(user.displayName);
      await _auth.currentUser!.reload();
    }
  }

  Future<String> getLatestDisplayName(String uid) async {
    try {
      final profile = await fetchProfile(uid);
      if (profile != null && profile.displayName.trim().isNotEmpty) {
        return profile.displayName.trim();
      }
    } catch (_) {}

    try {
      await _auth.currentUser?.reload();
    } catch (_) {}

    final authName = _auth.currentUser?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      return authName;
    }
    return _auth.currentUser?.email ?? 'ผู้ใช้';
  }
}
