import 'package:flutter/material.dart';

class AdminManagePayments extends StatefulWidget {
  const AdminManagePayments({super.key});

  @override
  State<AdminManagePayments> createState() => _AdminManagePaymentsState();
}

class _AdminManagePaymentsState extends State<AdminManagePayments> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payments'),
      ),
      body: const Center(
        child: Text('Payments Management Page'),
      ),
    );
  }
}
