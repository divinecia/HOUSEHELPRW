import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth_service.dart';
import '../../models/user_role.dart';
import './manage_hiring_requests.dart';
import './manage_house_helpers.dart';
import '../login.dart';
import './manage_chats.dart';
import './dashboard.dart';

class AdminManagePayments extends StatefulWidget {
  const AdminManagePayments({super.key});

  @override
  State<AdminManagePayments> createState() => _AdminManagePaymentsState();
}

class _AdminManagePaymentsState extends State<AdminManagePayments> {
  int _selectedIndex = 3; // Payments is selected
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  List<PaymentData> _payments = [];
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _verifyAdminRole();
    _loadSamplePayments();
  }

  Future<void> _verifyAdminRole() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final role = await authService.getCurrentUserRole();

    if (role != UserRole.admin) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  void _loadSamplePayments() {
    // Sample data for demonstration
    final samplePayments = [
      PaymentData(
        id: '1',
        amount: 15000,
        description: 'House cleaning service',
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: 'completed',
      ),
      PaymentData(
        id: '2',
        amount: 25000,
        description: 'Cooking and cleaning',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed',
      ),
      PaymentData(
        id: '3',
        amount: 12000,
        description: 'Babysitting service',
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: 'pending',
      ),
    ];

    setState(() {
      _payments = samplePayments;
      _totalRevenue = samplePayments.fold(
        0,
        (sum, payment) => sum + payment.amount,
      );
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: const Text(
              'Admin Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text(
              'Administrator',
              style: TextStyle(fontSize: 14),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, size: 48),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('House Helpers'),
            selected: _selectedIndex == 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageHouseHelpers(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Jobs'),
            selected: _selectedIndex == 2,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageHiringRequests(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Payments'),
            selected: _selectedIndex == 3,
            onTap: () {
              // Already on this page
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chats'),
            selected: _selectedIndex == 4,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminManageChats(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final authService = Provider.of<AuthService>(
                context,
                listen: false,
              );
              await authService.signout();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    if (_payments.isEmpty) {
      return const Center(
        child: Text(
          'No payments found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColorWithOpacity(payment.status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.payment,
                color: _getStatusColor(payment.status),
              ),
            ),
            title: Text(
              payment.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Date: ${DateFormat('MMM d, yyyy').format(payment.date)}\nStatus: ${payment.status}',
            ),
            trailing: Text(
              'RWF ${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getColorWithOpacity(Color color, double opacity) {
    return Color.fromRGBO(
      (color.r * 255.0).round() & 0xff,
      (color.g * 255.0).round() & 0xff,
      (color.b * 255.0).round() & 0xff,
      opacity,
    );
  }

  Color _getStatusColorWithOpacity(String status) {
    final color = _getStatusColor(status);
    return _getColorWithOpacity(color, 0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Manage Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSamplePayments,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Revenue Summary Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Revenue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'RWF ${_totalRevenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(76, 175, 80, 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.green,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Payments List
                Expanded(child: _buildPaymentsList()),
              ],
            ),
    );
  }
}

class PaymentData {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final String status;

  PaymentData({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.status,
  });
}
