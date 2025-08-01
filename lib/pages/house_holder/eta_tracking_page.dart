import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/household_service.dart';

class ETATrackingPage extends StatefulWidget {
  final String requestId;
  final String helperName;
  final String helperPhone;

  const ETATrackingPage({
    super.key,
    required this.requestId,
    required this.helperName,
    required this.helperPhone,
  });

  @override
  State<ETATrackingPage> createState() => _ETATrackingPageState();
}

class _ETATrackingPageState extends State<ETATrackingPage> {
  Map<String, dynamic>? _trackingData;
  bool _isLoading = true;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
    _startTracking();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _loadTrackingData() async {
    try {
      setState(() => _isLoading = true);

      final data = await HouseholdService.getETATracking(widget.requestId);

      setState(() {
        _trackingData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tracking data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tracking data: $e')),
        );
      }
    }
  }

  void _startTracking() {
    if (!_isTracking) {
      _isTracking = true;
      // Simulate real-time updates every 30 seconds
      Future.doWhile(() async {
        if (!_isTracking) return false;
        await Future.delayed(const Duration(seconds: 30));
        if (_isTracking && mounted) {
          await _loadTrackingData();
        }
        return _isTracking;
      });
    }
  }

  void _stopTracking() {
    _isTracking = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Helper'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrackingData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trackingData == null
              ? _buildNoTrackingData()
              : _buildTrackingContent(),
    );
  }

  Widget _buildNoTrackingData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tracking Not Available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The helper hasn\'t started their journey yet or tracking is not enabled.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _callHelper,
              icon: const Icon(Icons.phone),
              label: const Text('Call Helper'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent() {
    final eta = _trackingData!['estimated_arrival'];
    final status = _trackingData!['status'] ?? 'unknown';
    final distance = _trackingData!['distance_km'] ?? 0.0;
    final lastUpdate = _trackingData!['last_updated'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelperInfo(),
          const SizedBox(height: 20),
          _buildStatusCard(status),
          const SizedBox(height: 20),
          _buildETACard(eta, distance),
          const SizedBox(height: 20),
          _buildTrackingMap(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
          _buildLastUpdate(lastUpdate),
        ],
      ),
    );
  }

  Widget _buildHelperInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.helperName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.helperPhone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _callHelper,
              icon: const Icon(Icons.phone, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'on_the_way':
        statusColor = Colors.blue;
        statusIcon = Icons.directions_walk;
        statusText = 'On the way';
        break;
      case 'nearby':
        statusColor = Colors.orange;
        statusIcon = Icons.near_me;
        statusText = 'Nearby (within 1km)';
        break;
      case 'arrived':
        statusColor = Colors.green;
        statusIcon = Icons.location_on;
        statusText = 'Arrived';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Status unknown';
    }

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusColor.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(
              statusIcon,
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
            ),
            if (status.toLowerCase() == 'arrived') ...[
              const SizedBox(height: 8),
              Text(
                'Your helper has arrived!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: statusColor,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildETACard(String? eta, double distance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Arrival',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildETAItem(
                    'Time',
                    eta != null
                        ? DateFormat('HH:mm').format(DateTime.parse(eta))
                        : 'Calculating...',
                    Icons.access_time,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildETAItem(
                    'Distance',
                    '${distance.toStringAsFixed(1)} km',
                    Icons.straighten,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildETAItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildTrackingMap() {
    return Card(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Map View',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Real-time location tracking',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _callHelper,
            icon: const Icon(Icons.phone),
            label: const Text('Call Helper'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _sendMessage,
            icon: const Icon(Icons.message),
            label: const Text('Message'),
          ),
        ),
      ],
    );
  }

  Widget _buildLastUpdate(String? lastUpdate) {
    if (lastUpdate == null) return const SizedBox.shrink();

    final updateTime = DateTime.parse(lastUpdate);
    final now = DateTime.now();
    final difference = now.difference(updateTime);

    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} minutes ago';
    } else {
      timeAgo = '${difference.inHours} hours ago';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.update,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Last updated: $timeAgo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _callHelper() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Helper'),
        content: Text('Call ${widget.helperName} at ${widget.helperPhone}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, you would use url_launcher to make the call
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ${widget.helperPhone}...')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Message'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
