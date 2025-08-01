import 'package:flutter/material.dart';

class AdminManageUsers extends StatefulWidget {
  const AdminManageUsers({Key? key}) : super(key: key);

  @override
  State<AdminManageUsers> createState() => _AdminManageUsersState();
}

class _AdminManageUsersState extends State<AdminManageUsers> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: const Center(
        child: Text('User Management Page'),
      ),
    );
  }
}
