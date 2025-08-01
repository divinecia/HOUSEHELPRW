import 'package:flutter/material.dart';
import '../../models/house_helper_profile.dart';
import '../../services/house_helper_service.dart' as service;

class FindHelpersPage extends StatefulWidget {
  const FindHelpersPage({super.key});
  @override
  State<FindHelpersPage> createState() => _FindHelpersPageState();
}

class _FindHelpersPageState extends State<FindHelpersPage> {
  final service.HouseHelperService _houseHelperService =
      service.HouseHelperService();
  final TextEditingController _searchController = TextEditingController();

  List<HouseHelperProfile> _allHelpers = [];
  List<HouseHelperProfile> _filteredHelpers = [];
  bool _isLoading = true;
  String _selectedCity = 'All Cities';
  String _selectedService = 'All Services';
  double _maxHourlyRate = 100.0;

  List<String> _availableCities = ['All Cities'];
  final List<String> _services = [
    'All Services',
    'cleaning',
    'cooking',
    'childcare',
    'gardening',
    'laundry',
    'elderly_care',
  ];

  @override
  void initState() {
    super.initState();
    _loadHelpers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHelpers() async {
    try {
      setState(() => _isLoading = true);

      final helpers = await _houseHelperService.getAllProfiles();

      // Extract unique cities from helpers
      Set<String> cities = {'All Cities'};
      for (var helper in helpers) {
        if (helper.city.isNotEmpty) {
          cities.add(helper.city);
        }
      }

      setState(() {
        _allHelpers = List.from(
          helpers,
        ); // Use List.from to ensure new reference
        _filteredHelpers = List.from(helpers); // Initialize filtered list
        _availableCities = cities.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      String errorMessage;
      if (e.toString().contains('Access denied') ||
          e.toString().contains('permission')) {
        errorMessage =
            'Permission denied. Please contact the administrator to set up proper Firestore security rules.';
      } else if (e.toString().contains('unavailable')) {
        errorMessage =
            'Service temporarily unavailable. Please try again later.';
      } else {
        errorMessage = 'Error loading helpers: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadHelpers,
            ),
          ),
        );
      }
    }
  }

  void _filterHelpers() {
    setState(() {
      _filteredHelpers = _allHelpers.where((helper) {
        // Search filter
        final searchTerm = _searchController.text.toLowerCase().trim();
        final matchesSearch = searchTerm.isEmpty ||
            helper.fullName.toLowerCase().contains(searchTerm) ||
            helper.services.any(
              (service) => service.toLowerCase().contains(searchTerm),
            ) ||
            helper.city.toLowerCase().contains(searchTerm) ||
            helper.district.toLowerCase().contains(searchTerm) ||
            helper.description.toLowerCase().contains(searchTerm);

        // City filter
        final matchesCity =
            _selectedCity == 'All Cities' || helper.city == _selectedCity;

        // Service filter
        final matchesService = _selectedService == 'All Services' ||
            helper.services.contains(_selectedService);

        // Rate filter
        final matchesRate = helper.hourlyRate <= _maxHourlyRate;

        return matchesSearch && matchesCity && matchesService && matchesRate;
      }).toList();

      // Sort by hourly rate (ascending) and then by name
      _filteredHelpers.sort((a, b) {
        int rateComparison = a.hourlyRate.compareTo(b.hourlyRate);
        if (rateComparison != 0) return rateComparison;
        return a.fullName.compareTo(b.fullName);
      });
    });
  }

  // Replace the _clearFilters() method with this fixed version:
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCity = 'All Cities';
      _selectedService = 'All Services';
      _maxHourlyRate = 100.0;
    });
    _filterHelpers(); // Call _filterHelpers instead of manually setting _filteredHelpers
  }

  void _showHelperDetails(HouseHelperProfile helper) {
    showDialog(
      context: context,
      builder: (context) => HelperDetailsModal(helper: helper),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Find House Helpers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHelpers),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Search and Filter Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade700, Colors.blue.shade600],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search Bar with enhanced styling
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => _filterHelpers(),
                          decoration: InputDecoration(
                            hintText:
                                'Search by name, service, city, or description...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.blue.shade700,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterHelpers();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Row with improved styling
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCity,
                                onChanged: (value) {
                                  setState(() => _selectedCity = value!);
                                  _filterHelpers();
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.location_city,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                items: _availableCities
                                    .map(
                                      (city) => DropdownMenuItem(
                                        value: city,
                                        child: Text(
                                          city,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedService,
                                onChanged: (value) {
                                  setState(() => _selectedService = value!);
                                  _filterHelpers();
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.work_outline,
                                    color: Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                items: _services
                                    .map(
                                      (service) => DropdownMenuItem(
                                        value: service,
                                        child: Text(
                                          service == 'All Services'
                                              ? service
                                              : service
                                                  .replaceAll('_', ' ')
                                                  .toUpperCase(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Rate Slider with enhanced styling
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Max Hourly Rate: \$${_maxHourlyRate.toInt()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (_searchController.text.isNotEmpty ||
                              _selectedCity != 'All Cities' ||
                              _selectedService != 'All Services' ||
                              _maxHourlyRate != 100.0)
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.blue.shade700,
                          inactiveTrackColor: Colors.blue.shade100,
                          thumbColor: Colors.blue.shade700,
                          overlayColor:
                              Colors.blue.shade700.withValues(alpha: 0.2),
                          valueIndicatorColor: Colors.blue.shade700,
                        ),
                        child: Slider(
                          value: _maxHourlyRate,
                          min: 5.0,
                          max: 10000.0,
                          divisions: 29,
                          label: '\$${_maxHourlyRate.toInt()}',
                          onChanged: (value) {
                            setState(() => _maxHourlyRate = value);
                            _filterHelpers();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results Section with enhanced styling
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading helpers...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _filteredHelpers.isEmpty
                    ? _buildEmptyState()
                    : _buildHelpersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No helpers found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria or filters',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Clear All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpersList() {
    return RefreshIndicator(
      onRefresh: _loadHelpers,
      child: Column(
        children: [
          // Results Count with improved styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_filteredHelpers.length} helper${_filteredHelpers.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                if (_filteredHelpers.isNotEmpty)
                  Text(
                    'Sorted by rate',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          // Helpers List with improved cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHelpers.length,
              itemBuilder: (context, index) {
                final helper = _filteredHelpers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: EnhancedHelperCard(
                    helper: helper,
                    onTap: () => _showHelperDetails(helper),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedHelperCard extends StatelessWidget {
  final HouseHelperProfile helper;
  final VoidCallback onTap;

  const EnhancedHelperCard({
    super.key,
    required this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Profile Image
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: helper.profileImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  helper.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(),
                                ),
                              )
                            : _buildDefaultAvatar(),
                      ),
                      if (helper.hasReferences)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Helper Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Rate Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                helper.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'FRW${helper.hourlyRate.toInt()}/hr',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Location Row
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${helper.city}, ${helper.district}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Experience and Availability Row
                        Row(
                          children: [
                            if (helper.experienceYears > 0) ...[
                              Icon(
                                Icons.work,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${helper.experienceYears}y exp',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                helper.availability
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Services Tags
              if (helper.services.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: helper.services.take(3).map((service) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            service.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        );
                      }).toList()
                        ..addAll(
                          helper.services.length > 3
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '+${helper.services.length - 3} more',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      ),
      child: const Icon(Icons.person, size: 30, color: Colors.white),
    );
  }
}

class HelperDetailsModal extends StatelessWidget {
  final HouseHelperProfile helper;

  const HelperDetailsModal({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: helper.profileImageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              helper.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 40),
                            ),
                          )
                        : const Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          helper.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${helper.city}, ${helper.district}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rate and Experience
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Hourly Rate',
                            'FRW${helper.hourlyRate.toInt()}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            'Experience',
                            '${helper.experienceYears} years',
                            Icons.work,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Contact Info
                    _buildSection('Contact Information', [
                      _buildDetailRow(Icons.phone, 'Phone', helper.phoneNumber),
                      _buildDetailRow(Icons.home, 'Address', helper.address),
                    ]),
                    const SizedBox(height: 20),
                    // Services
                    _buildSection('Services Offered', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: helper.services.map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              service.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Languages
                    _buildSection('Languages', [
                      Text(
                        helper.languages.join(', '),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Availability
                    _buildSection('Availability', [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          helper.availability.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Description
                    _buildSection('About', [
                      Text(
                        helper.description.isEmpty
                            ? 'No description provided.'
                            : helper.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // References
                    if (helper.hasReferences)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'References Available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
