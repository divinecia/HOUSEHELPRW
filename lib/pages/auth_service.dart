import '../models/user_role.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class User {
  final String uid;
  final String email;
  final String? displayName;
  final UserRole? role;

  User({required this.uid, required this.email, this.displayName, this.role});
}

class AuthService {
  static final SupabaseClient _supabase = SupabaseConfig.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<UserRole?> getCurrentUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final roleString = profile['role'] as String?;
      switch (roleString) {
        case 'admin':
          return UserRole.admin;
        case 'house_helper':
          return UserRole.house_helper;
        case 'house_holder':
          return UserRole.house_holder;
        default:
          return null;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  Future<void> signout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
  }

  // Alternative method name for compatibility
  Future<void> signOut() async {
    await signout();
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final role = await getCurrentUserRole();
        _currentUser = User(
          uid: response.user!.id,
          email: response.user!.email!,
          displayName: response.user!.userMetadata?['display_name'],
          role: role,
        );
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
