import 'package:flutter/material.dart';
import '../../models/house_helper_profile.dart';

class HireHelperPage extends StatefulWidget {
  final HouseHelperProfile helper;

  const HireHelperPage({Key? key, required this.helper}) : super(key: key);

  @override
  State<HireHelperPage> createState() => _HireHelperPageState();
}

class _HireHelperPageState extends State<HireHelperPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hire ${widget.helper.fullName}'),
      ),
      body: Center(
        child: Text('Hire Helper Page for ${widget.helper.fullName}'),
      ),
    );
  }
}
