class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String studentId;
  final bool isAdmin;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.studentId,
    this.isAdmin = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      studentId: data['studentId'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'studentId': studentId,
      'isAdmin': isAdmin,
    };
  }
}
