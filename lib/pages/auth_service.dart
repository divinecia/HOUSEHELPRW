import '../models/user_role.dart';

class User {
  final String uid;
  final String email;
  final String? displayName;

  User({required this.uid, required this.email, this.displayName});
}

class AuthService {
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<UserRole?> getCurrentUserRole() async {
    // Placeholder implementation - always returns admin for now
    return UserRole.admin;
  }

  Future<void> signout() async {
    // Placeholder signout
    _currentUser = null;
  }

  Future<void> signIn(String email, String password) async {
    // Placeholder sign in
    _currentUser =
        User(uid: 'test_uid', email: email, displayName: 'Test User');
  }
}
