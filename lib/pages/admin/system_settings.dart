import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  SystemSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _taxRateController = TextEditingController();
  final _serviceFeeController = TextEditingController();

  String _selectedLanguage = 'en';
  bool _enableEmailNotifications = true;
  bool _enablePushNotifications = true;
  bool _enableSMSNotifications = false;
  bool _enableEjoHeza = false;
  bool _enableInsurance = false;
  double _minimumPayment = 1000.0;
  double _maximumPayment = 500000.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    _serviceFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      final settings = await AdminService.getSystemSettings();

      if (settings != null) {
        setState(() {
          _settings = settings;
          _selectedLanguage = settings.defaultLanguage;
          _taxRateController.text = (settings.taxRate * 100).toStringAsFixed(1);
          _serviceFeeController.text =
              (settings.serviceFeePercentage * 100).toStringAsFixed(1);

          // Load notification settings
          final notificationSettings = settings.notificationSettings;
          _enableEmailNotifications = notificationSettings['email'] ?? true;
          _enablePushNotifications = notificationSettings['push'] ?? true;
          _enableSMSNotifications = notificationSettings['sms'] ?? false;

          // Load benefits options
          final benefitsOptions = settings.benefitsOptions;
          _enableEjoHeza = benefitsOptions['ejo_heza'] ?? false;
          _enableInsurance = benefitsOptions['insurance'] ?? false;

          // Load payment settings
          final paymentSettings = settings.paymentSettings;
          _minimumPayment =
              (paymentSettings['minimum_payment'] ?? 1000).toDouble();
          _maximumPayment =
              (paymentSettings['maximum_payment'] ?? 500000).toDouble();
        });
      } else {
        // Create default settings if none exist
        _createDefaultSettings();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading settings: $e');
    }
  }

  Future<void> _createDefaultSettings() async {
    final defaultSettings = SystemSettings(
      defaultLanguage: 'en',
      taxRate: 0.18,
      serviceFeePercentage: 0.05,
      benefitsOptions: {
        'ejo_heza': false,
        'insurance': false,
      },
      notificationSettings: {
        'email': true,
        'push': true,
        'sms': false,
      },
      paymentSettings: {
        'minimum_payment': 1000,
        'maximum_payment': 500000,
        'supported_providers': ['MTN', 'Airtel'],
      },
      lastUpdated: DateTime.now(),
      updatedBy: 'Admin',
    );

    setState(() => _settings = defaultSettings);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final updatedSettings = SystemSettings(
        id: _settings?.id,
        defaultLanguage: _selectedLanguage,
        taxRate: double.parse(_taxRateController.text) / 100,
        serviceFeePercentage: double.parse(_serviceFeeController.text) / 100,
        benefitsOptions: {
          'ejo_heza': _enableEjoHeza,
          'insurance': _enableInsurance,
        },
        notificationSettings: {
          'email': _enableEmailNotifications,
          'push': _enablePushNotifications,
          'sms': _enableSMSNotifications,
        },
        paymentSettings: {
          'minimum_payment': _minimumPayment,
          'maximum_payment': _maximumPayment,
          'supported_providers': ['MTN', 'Airtel'],
        },
        lastUpdated: DateTime.now(),
        updatedBy: 'Admin',
      );

      await AdminService.updateSystemSettings(updatedSettings);
      setState(() {
        _settings = updatedSettings;
        _isSaving = false;
      });

      _showSuccessSnackBar('Settings saved successfully');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to save settings: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralSettings(),
                    const SizedBox(height: 32),
                    _buildFinancialSettings(),
                    const SizedBox(height: 32),
                    _buildNotificationSettings(),
                    const SizedBox(height: 32),
                    _buildBenefitsSettings(),
                    const SizedBox(height: 32),
                    _buildPaymentSettings(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Default Language',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'rw', child: Text('Kinyarwanda')),
                DropdownMenuItem(value: 'fr', child: Text('French')),
              ],
              onChanged: (value) =>
                  setState(() => _selectedLanguage = value ?? 'en'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxRateController,
                    decoration: const InputDecoration(
                      labelText: 'Tax Rate (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter tax rate';
                      }
                      final rate = double.tryParse(value);
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Enter a valid percentage (0-100)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _serviceFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Service Fee (%)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter service fee';
                      }
                      final fee = double.tryParse(value);
                      if (fee == null || fee < 0 || fee > 100) {
                        return 'Enter a valid percentage (0-100)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Send notifications via email'),
              value: _enableEmailNotifications,
              onChanged: (value) =>
                  setState(() => _enableEmailNotifications = value),
              secondary: const Icon(Icons.email),
            ),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Send push notifications to mobile devices'),
              value: _enablePushNotifications,
              onChanged: (value) =>
                  setState(() => _enablePushNotifications = value),
              secondary: const Icon(Icons.notifications),
            ),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Send notifications via SMS'),
              value: _enableSMSNotifications,
              onChanged: (value) =>
                  setState(() => _enableSMSNotifications = value),
              secondary: const Icon(Icons.sms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benefits & Welfare',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ejo Heza Integration'),
              subtitle: const Text('Enable Ejo Heza savings program'),
              value: _enableEjoHeza,
              onChanged: (value) => setState(() => _enableEjoHeza = value),
              secondary: const Icon(Icons.savings),
            ),
            SwitchListTile(
              title: const Text('Insurance Options'),
              subtitle: const Text('Enable worker insurance programs'),
              value: _enableInsurance,
              onChanged: (value) => setState(() => _enableInsurance = value),
              secondary: const Icon(Icons.health_and_safety),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum Payment: ${_minimumPayment.toStringAsFixed(0)} RWF',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Slider(
                        value: _minimumPayment,
                        min: 500,
                        max: 10000,
                        divisions: 19,
                        onChanged: (value) =>
                            setState(() => _minimumPayment = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum Payment: ${_maximumPayment.toStringAsFixed(0)} RWF',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Slider(
                        value: _maximumPayment,
                        min: 100000,
                        max: 1000000,
                        divisions: 18,
                        onChanged: (value) =>
                            setState(() => _maximumPayment = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supported Payment Providers:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('MTN Mobile Money'),
                        avatar: Icon(Icons.phone_android, size: 16),
                      ),
                      Chip(
                        label: Text('Airtel Money'),
                        avatar: Icon(Icons.phone_android, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveSettings,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
