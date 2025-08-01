import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/worker_service.dart';
import '../../services/supabase_auth_service.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Profile data
  Map<String, dynamic>? _workerProfile;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final _villageController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _bankAccountController = TextEditingController();

  // Selected values
  List<String> _selectedServices = [];
  String? _selectedInsuranceProvider;
  bool _ejoHezaOptIn = false;
  String? _selectedTaxStatus;
  String? _selectedLanguage;

  // Available options
  final List<String> _availableServices = [
    'House Cleaning',
    'Cooking',
    'Laundry',
    'Child Care',
    'Elder Care',
    'Garden Maintenance',
    'Shopping Assistant',
    'Pet Care',
    'Home Security',
    'General Maintenance',
  ];

  final List<String> _insuranceProviders = [
    'RSSB',
    'MMI',
    'Radiant Insurance',
    'SONARWA',
    'Prime Insurance',
    'Other',
  ];

  final List<String> _taxStatuses = [
    'Individual Taxpayer',
    'Not Registered',
    'Exempted',
  ];

  final List<String> _languages = [
    'English',
    'Kinyarwanda',
    'French',
    'Swahili'
  ];

  @override
  void initState() {
    super.initState();
    _loadWorkerProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _cellController.dispose();
    _villageController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerProfile() async {
    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      final profile = await WorkerService.getWorkerProfile(user.id);

      if (profile != null && mounted) {
        setState(() {
          _workerProfile = profile;
          _populateFields(profile);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _populateFields(Map<String, dynamic> profile) {
    final profileData = profile['profiles'] ?? {};

    _fullNameController.text = profileData['full_name'] ?? '';
    _phoneController.text = profileData['phone_number'] ?? '';
    _emailController.text = profileData['email'] ?? '';
    _districtController.text = profileData['district'] ?? '';
    _sectorController.text = profileData['sector'] ?? '';
    _cellController.text = profileData['cell'] ?? '';
    _villageController.text = profileData['village'] ?? '';
    _selectedLanguage = profileData['preferred_language'] ?? 'English';

    _hourlyRateController.text = profile['hourly_rate']?.toString() ?? '';
    _experienceController.text = profile['experience'] ?? '';
    _bioController.text = profile['bio'] ?? '';
    _bankAccountController.text = profile['bank_account'] ?? '';

    _selectedServices = List<String>.from(profile['services'] ?? []);
    _selectedInsuranceProvider = profile['insurance_provider'];
    _ejoHezaOptIn = profile['ejo_heza_opt_in'] ?? false;
    _selectedTaxStatus = profile['tax_status'];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfilePictureSection(),
              const SizedBox(height: 24),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildServicesSection(),
              const SizedBox(height: 24),
              _buildProfessionalInfoSection(),
              const SizedBox(height: 24),
              _buildInsuranceSection(),
              const SizedBox(height: 24),
              _buildDocumentUploadSection(),
              const SizedBox(height: 24),
              _buildVerificationStatusSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final profilePictureUrl =
        _workerProfile?['profiles']?['profile_picture_url'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: profilePictureUrl != null
                  ? NetworkImage(profilePictureUrl)
                  : null,
              child: profilePictureUrl == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _uploadProfilePicture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Change Picture'),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixText: '+250 ',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 9) {
                  return 'Phone number must be 9 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: const InputDecoration(
                labelText: 'Preferred Language',
                border: OutlineInputBorder(),
              ),
              items: _languages
                  .map((language) => DropdownMenuItem(
                        value: language,
                        child: Text(language),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
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
              'Location Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your district';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sectorController,
              decoration: const InputDecoration(
                labelText: 'Sector',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your sector';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cellController,
              decoration: const InputDecoration(
                labelText: 'Cell',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _villageController,
              decoration: const InputDecoration(
                labelText: 'Village',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your village';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services Offered',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableServices.map((service) {
                final isSelected = _selectedServices.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_selectedServices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Please select at least one service',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hourlyRateController,
              decoration: const InputDecoration(
                labelText: 'Hourly Rate (RWF)',
                border: OutlineInputBorder(),
                prefixText: 'RWF ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your hourly rate';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                labelText: 'Years of Experience',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio / Description',
                border: OutlineInputBorder(),
                hintText:
                    'Tell potential clients about yourself and your experience...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountController,
              decoration: const InputDecoration(
                labelText: 'Bank Account Number (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insurance & Tax Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedInsuranceProvider,
              decoration: const InputDecoration(
                labelText: 'Insurance Provider',
                border: OutlineInputBorder(),
              ),
              items: _insuranceProviders
                  .map((provider) => DropdownMenuItem(
                        value: provider,
                        child: Text(provider),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInsuranceProvider = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select an insurance provider';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Opt-in to Ejo Heza'),
              subtitle: const Text('Community-based health insurance'),
              value: _ejoHezaOptIn,
              onChanged: (value) {
                setState(() {
                  _ejoHezaOptIn = value ?? false;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTaxStatus,
              decoration: const InputDecoration(
                labelText: 'Tax Status',
                border: OutlineInputBorder(),
              ),
              items: _taxStatuses
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTaxStatus = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your tax status';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Upload',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('National ID'),
              subtitle: const Text('Upload your national ID card'),
              trailing: ElevatedButton(
                onPressed: () => _uploadDocument('id_card'),
                child: const Text('Upload'),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Certificates'),
              subtitle: const Text('Upload relevant certificates (optional)'),
              trailing: ElevatedButton(
                onPressed: () => _uploadDocument('certificate'),
                child: const Text('Upload'),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('References'),
              subtitle: const Text('Upload reference letters (optional)'),
              trailing: ElevatedButton(
                onPressed: () => _uploadDocument('reference'),
                child: const Text('Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatusSection() {
    final verificationStatus =
        _workerProfile?['verification_status'] ?? 'pending';
    final adminNotes = _workerProfile?['admin_notes'];

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (verificationStatus) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        statusText = 'Verified';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending Verification';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Verification Status: $statusText',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
              ],
            ),
            if (adminNotes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Admin Notes:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(adminNotes),
            ],
            if (verificationStatus == 'pending') ...[
              const SizedBox(height: 8),
              const Text(
                'Your profile is under review. You will receive notifications once verification is complete.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final user = SupabaseAuthService.getCurrentUser();

        if (user != null && file.bytes != null) {
          final url = await WorkerService.uploadWorkerProfilePicture(
            workerId: user.id,
            filePath: file.name,
            fileBytes: file.bytes!,
          );

          if (url != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile picture updated successfully')),
            );
            _loadWorkerProfile(); // Refresh profile data
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading picture: $e')),
        );
      }
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final user = SupabaseAuthService.getCurrentUser();

        if (user != null && file.bytes != null) {
          final url = await WorkerService.uploadVerificationDocument(
            workerId: user.id,
            documentType: documentType,
            filePath: file.name,
            fileBytes: file.bytes!,
          );

          if (url != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document uploaded successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      await WorkerService.updateWorkerProfile(
        workerId: user.id,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        district: _districtController.text.trim(),
        sector: _sectorController.text.trim(),
        cell: _cellController.text.trim().isEmpty
            ? null
            : _cellController.text.trim(),
        village: _villageController.text.trim(),
        preferredLanguage: _selectedLanguage,
        services: _selectedServices,
        hourlyRate: double.tryParse(_hourlyRateController.text),
        insuranceProvider: _selectedInsuranceProvider,
        ejoHezaOptIn: _ejoHezaOptIn,
        taxStatus: _selectedTaxStatus,
        bankAccount: _bankAccountController.text.trim().isEmpty
            ? null
            : _bankAccountController.text.trim(),
        experience: _experienceController.text.trim().isEmpty
            ? null
            : _experienceController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
