import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/household_service.dart';
import '../auth_service.dart';
import '../login.dart';

class HouseholdSettingsPage extends StatefulWidget {
  const HouseholdSettingsPage({super.key});

  @override
  State<HouseholdSettingsPage> createState() => _HouseholdSettingsPageState();
}

class _HouseholdSettingsPageState extends State<HouseholdSettingsPage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _currentUserId;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedLanguage = 'en';
  String _selectedDistrict = '';
  String _selectedSector = '';
  String _selectedCell = '';
  String _selectedVillage = '';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'rw', 'name': 'Kinyarwanda'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'sw', 'name': 'Kiswahili'},
  ];

  final List<String> _districts = [
    'Kigali',
    'Northern Province',
    'Southern Province',
    'Eastern Province',
    'Western Province'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);

      _currentUserId = AuthService().currentUser?.uid ?? 'demo_household_id';

      final profile =
          await HouseholdService.getHouseholdProfile(_currentUserId!);

      if (profile != null) {
        setState(() {
          _profile = profile;
          _fullNameController.text = profile['full_name'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _addressController.text = profile['address'] ?? '';
          _selectedLanguage = profile['preferred_language'] ?? 'en';
          _selectedDistrict = profile['district'] ?? '';
          _selectedSector = profile['sector'] ?? '';
          _selectedCell = profile['cell'] ?? '';
          _selectedVillage = profile['village'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isUpdating ? null : _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePictureSection(),
            const SizedBox(height: 24),
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),
            _buildLocationSection(),
            const SizedBox(height: 24),
            _buildPreferencesSection(),
            const SizedBox(height: 24),
            _buildSubscriptionSection(),
            const SizedBox(height: 24),
            _buildAccountSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Picture',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profile?['profile_picture_url'] != null
                      ? NetworkImage(_profile!['profile_picture_url'])
                      : null,
                  child: _profile?['profile_picture_url'] == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickAndUploadImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Change Picture'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a clear photo of yourself for better trust with helpers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
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

  Widget _buildPersonalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Home Address',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDistrict.isEmpty ? null : _selectedDistrict,
              decoration: const InputDecoration(
                labelText: 'District',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              items: _districts
                  .map((district) => DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedDistrict = value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _selectedSector,
              decoration: const InputDecoration(
                labelText: 'Sector',
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _selectedSector = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _selectedCell,
              decoration: const InputDecoration(
                labelText: 'Cell',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _selectedCell = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _selectedVillage,
              decoration: const InputDecoration(
                labelText: 'Village',
                prefixIcon: Icon(Icons.home_work),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _selectedVillage = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'App Language',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
              ),
              items: _languages
                  .map((lang) => DropdownMenuItem(
                        value: lang['code'],
                        child: Text(lang['name']!),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedLanguage = value ?? 'en'),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              subtitle: const Text('Manage your notifications'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showNotificationSettings,
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy & Security'),
              subtitle: const Text('Control your privacy settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showPrivacySettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscriptions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Premium Workers'),
              subtitle: const Text('Manage your worker subscriptions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showSubscriptions,
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment History'),
              subtitle: const Text('View all your payments'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showPaymentHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help or contact support'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showHelp,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('App version and information'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showAbout,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _showLogoutDialog,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _saveProfile,
                child: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        setState(() => _isUpdating = true);

        final imageUrl = await HouseholdService.uploadProfilePicture(
          userId: _currentUserId!,
          filePath: image.path,
          fileBytes: Uint8List.fromList(bytes),
        );

        if (imageUrl != null && mounted) {
          setState(() {
            _profile = {..._profile!, 'profile_picture_url': imageUrl};
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      await HouseholdService.updateHouseholdProfile(
        userId: _currentUserId!,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        district: _selectedDistrict,
        sector: _selectedSector,
        cell: _selectedCell,
        village: _selectedVillage,
        preferredLanguage: _selectedLanguage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text('Hire Request Updates'),
              value: true,
              onChanged: null,
            ),
            CheckboxListTile(
              title: Text('Worker Arrival Notifications'),
              value: true,
              onChanged: null,
            ),
            CheckboxListTile(
              title: Text('Payment Confirmations'),
              value: true,
              onChanged: null,
            ),
            CheckboxListTile(
              title: Text('Promotional Messages'),
              value: false,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Change Password'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              title: Text('Two-Factor Authentication'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              title: Text('Data & Privacy'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionManagementPage(),
      ),
    );
  }

  void _showPaymentHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening payment history...')),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: support@househelprw.com'),
            SizedBox(height: 8),
            Text('📞 Phone: +250 xxx xxx xxx'),
            SizedBox(height: 8),
            Text('💬 WhatsApp: +250 xxx xxx xxx'),
            SizedBox(height: 16),
            Text('Operating Hours:'),
            Text('Monday - Friday: 8:00 AM - 6:00 PM'),
            Text('Saturday: 9:00 AM - 5:00 PM'),
            Text('Sunday: Closed'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About HOUSEHELP'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('© 2025 HOUSEHELP Rwanda'),
            SizedBox(height: 16),
            Text(
                'HOUSEHELP connects households with trusted domestic workers in Rwanda. Find verified helpers for cleaning, cooking, childcare, and more.'),
            SizedBox(height: 16),
            Text('Built with ❤️ for Rwanda'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = AuthService();
              await authService.signout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      setState(() => _isLoading = true);

      final subscriptions =
          await HouseholdService.getHouseholdSubscriptions('demo_household_id');

      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading subscriptions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? _buildEmptyState()
              : _buildSubscriptionsList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Active Subscriptions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Subscribe to premium workers for priority booking'),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = _subscriptions[index];
        final isActive = subscription['is_active'] == true &&
            DateTime.parse(subscription['expiry_date']).isAfter(DateTime.now());

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: subscription['worker_picture'] != null
                  ? NetworkImage(subscription['worker_picture'])
                  : null,
              child: subscription['worker_picture'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(subscription['worker_name'] ?? 'Unknown Worker'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${subscription['subscription_type']}'),
                Text('Expires: ${subscription['expiry_date']}'),
                Text(
                  isActive ? 'Active' : 'Expired',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: isActive
                ? PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleSubscriptionAction(action, subscription),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancel Subscription'),
                      ),
                    ],
                  )
                : const Icon(Icons.schedule, color: Colors.grey),
          ),
        );
      },
    );
  }

  void _handleSubscriptionAction(
      String action, Map<String, dynamic> subscription) async {
    if (action == 'cancel') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Subscription'),
          content:
              Text('Cancel subscription to ${subscription['worker_name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await HouseholdService.cancelSubscription(subscription['id']);
          await _loadSubscriptions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subscription cancelled')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to cancel: $e')),
            );
          }
        }
      }
    }
  }
}
