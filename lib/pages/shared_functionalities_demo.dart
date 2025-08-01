import 'package:flutter/material.dart';
import '../middleware/route_guard.dart';
import '../models/user_role.dart';
import '../services/emergency_service.dart';
import '../services/export_service.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../pages/emergency_contacts.dart';

/// Example admin page showing shared functionality usage
class SharedFunctionalitiesDemo extends StatefulWidget {
  const SharedFunctionalitiesDemo({super.key});

  @override
  _SharedFunctionalitiesDemoState createState() =>
      _SharedFunctionalitiesDemoState();
}

class _SharedFunctionalitiesDemoState extends State<SharedFunctionalitiesDemo> {
  String _currentLanguage = 'en';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final lang = await LocalizationService.getCurrentLanguage();
    setState(() {
      _currentLanguage = lang;
    });
  }

  Future<void> _changeLanguage(String languageCode) async {
    setState(() => _isLoading = true);
    await LocalizationService.setLanguage(languageCode);
    setState(() {
      _currentLanguage = languageCode;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.translate('language_changed',
            languageCode: languageCode)),
      ),
    );
  }

  Future<void> _exportData(String dataType) async {
    setState(() => _isLoading = true);

    try {
      String? filePath;

      switch (dataType) {
        case 'users':
          filePath = await ExportService.exportUsersToCSV();
          break;
        case 'hiring':
          filePath = await ExportService.exportHiringRequestsToCSV();
          break;
        case 'payments':
          filePath = await ExportService.exportPaymentsToCSV();
          break;
        case 'training':
          filePath = await ExportService.exportTrainingToCSV();
          break;
        case 'system_report':
          filePath = await ExportService.exportSystemReportToJSON();
          break;
      }

      if (filePath != null) {
        await ExportService.shareFile(
            filePath, 'HouseHelp ${dataType.toUpperCase()} Export');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$dataType data exported successfully')),
        );
      } else {
        throw Exception('Export failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.initialize();

      await NotificationService.showLocalNotification(
        id: 999,
        title: 'Test Notification',
        body: 'This is a test notification from HouseHelp app',
        data: {'test': 'true'},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeEmergencyContacts() async {
    setState(() => _isLoading = true);

    try {
      await EmergencyService.initializeEmergencyContacts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contacts initialized')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initialization failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminRouteGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocalizationService.translate('app_name',
              languageCode: _currentLanguage)),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.language),
              onSelected: _changeLanguage,
              itemBuilder: (context) {
                return LocalizationService.getAvailableLanguages().map((lang) {
                  return PopupMenuItem(
                    value: lang,
                    child: Row(
                      children: [
                        if (lang == _currentLanguage)
                          const Icon(Icons.check, size: 20),
                        if (lang == _currentLanguage) const SizedBox(width: 8),
                        Text(LocalizationService.getLanguageName(lang)),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('🌐 Shared Functionalities Demo'),
                    const SizedBox(height: 20),
                    _buildLanguageSection(),
                    const SizedBox(height: 20),
                    _buildNotificationSection(),
                    const SizedBox(height: 20),
                    _buildExportSection(),
                    const SizedBox(height: 20),
                    _buildEmergencySection(),
                    const SizedBox(height: 20),
                    _buildRouteGuardSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.translate('language',
                      languageCode: _currentLanguage),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Current Language: ${LocalizationService.getLanguageName(_currentLanguage)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: LocalizationService.getAvailableLanguages().map((lang) {
                final isSelected = lang == _currentLanguage;
                return FilterChip(
                  label: Text(LocalizationService.getLanguageName(lang)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && !isSelected) {
                      _changeLanguage(lang);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sample translations:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                'welcome',
                'dashboard',
                'profile',
                'payment',
                'emergency',
              ].map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$key: ',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Expanded(
                        child: Text(LocalizationService.translate(key,
                            languageCode: _currentLanguage)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.translate('notifications',
                      languageCode: _currentLanguage),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
                'Enhanced notification system with Firebase Cloud Messaging support'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send Test Notification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.translate('export',
                      languageCode: _currentLanguage),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Export system data to CSV/JSON formats'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'users',
                'hiring',
                'payments',
                'training',
                'system_report',
              ].map((dataType) {
                return ElevatedButton(
                  onPressed: () => _exportData(dataType),
                  child: Text('Export ${dataType.toUpperCase()}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.translate('emergency',
                      languageCode: _currentLanguage),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Rwanda emergency contacts with toll numbers'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyContactsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('View Emergency Contacts'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _initializeEmergencyContacts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Initialize Contacts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteGuardSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  LocalizationService.translate('security',
                      languageCode: _currentLanguage),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Role-based authentication and route protection'),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Route Guards:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text('• AdminRouteGuard - Admin only pages'),
                const Text('• HouseHelperRouteGuard - Worker only pages'),
                const Text('• HouseholdRouteGuard - Household only pages'),
                const Text('• MultiRoleRouteGuard - Multiple roles'),
                const Text('• RouteGuard - Custom role configuration'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'You are viewing this page as an Admin',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
