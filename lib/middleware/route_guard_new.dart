import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';
import '../pages/login.dart';

class RouteGuard extends StatefulWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;
  final UserRole? requiredRole;
  final String? redirectRoute;
  final bool requiresVerification;
  final bool requiresCompleteProfile;
  final Function(BuildContext, String)? onAccessDenied;

  const RouteGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requiredRole,
    this.redirectRoute,
    this.requiresVerification = false,
    this.requiresCompleteProfile = false,
    this.onAccessDenied,
  });

  @override
  _RouteGuardState createState() => _RouteGuardState();
}

class _RouteGuardState extends State<RouteGuard> {
  late StreamSubscription<AuthState> _authSubscription;
  User? _currentUser;
  String? _userRole;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    try {
      // Listen to auth state changes
      _authSubscription =
          Supabase.instance.client.auth.onAuthStateChange.listen(
        (AuthState state) async {
          if (mounted) {
            await _handleAuthStateChange(state);
          }
        },
      );

      // Get initial auth state
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await _getUserProfile(user.id);
        final role = profile?['role'];
        setState(() {
          _currentUser = user;
          _userRole = role;
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = null;
          _userRole = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAuthStateChange(AuthState state) async {
    try {
      final user = state.session?.user;

      if (user != null) {
        final profile = await _getUserProfile(user.id);
        final role = profile?['role'];
        setState(() {
          _currentUser = user;
          _userRole = role;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _currentUser = null;
          _userRole = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: $e';
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  bool _hasRequiredRole() {
    if (_userRole == null) return false;

    // Check specific required role
    if (widget.requiredRole != null) {
      return _userRole == widget.requiredRole.toString().split('.').last;
    }

    // Check allowed roles list
    if (widget.allowedRoles != null) {
      final allowedRoleStrings = widget.allowedRoles!
          .map((role) => role.toString().split('.').last)
          .toList();
      return allowedRoleStrings.contains(_userRole);
    }

    return true; // No role restrictions
  }

  Future<void> _logAccessAttempt(String reason) async {
    try {
      if (_currentUser != null) {
        await Supabase.instance.client.from('security_logs').insert({
          'user_id': _currentUser!.id,
          'event_type': 'unauthorized_access_attempt',
          'details': {
            'user_role': _userRole ?? 'unknown',
            'reason': reason,
            'timestamp': DateTime.now().toIso8601String(),
          },
        });
      }
    } catch (e) {
      print('Error logging access attempt: $e');
    }
  }

  void _handleAccessDenied(String reason) {
    _logAccessAttempt(reason);

    if (widget.onAccessDenied != null) {
      widget.onAccessDenied!(context, reason);
      return;
    }

    // Default behavior: redirect to login
    if (_currentUser == null) {
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking permissions...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Authentication Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _initializeAuth(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user is authenticated
    if (_currentUser == null) {
      _handleAccessDenied('User not authenticated');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please log in to access this page.'),
            ],
          ),
        ),
      );
    }

    // Check role permissions
    if (!_hasRequiredRole()) {
      _handleAccessDenied('Insufficient role permissions');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Unauthorized Access',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You do not have permission to access this page.'),
            ],
          ),
        ),
      );
    }

    // User is authenticated and has required permissions
    return widget.child;
  }
}

// Helper widget for admin-only routes
class AdminRouteGuard extends StatelessWidget {
  final Widget child;

  const AdminRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      requiredRole: UserRole.admin,
      child: child,
    );
  }
}

// Helper widget for house helper routes
class HouseHelperRouteGuard extends StatelessWidget {
  final Widget child;

  const HouseHelperRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      requiredRole: UserRole.house_helper,
      child: child,
    );
  }
}

// Helper widget for household routes
class HouseholdRouteGuard extends StatelessWidget {
  final Widget child;

  const HouseholdRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      requiredRole: UserRole.house_holder,
      child: child,
    );
  }
}

// Multi-role route guard
class MultiRoleRouteGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole> allowedRoles;

  const MultiRoleRouteGuard({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      allowedRoles: allowedRoles,
      child: child,
    );
  }
}
