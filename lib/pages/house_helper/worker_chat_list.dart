import 'package:flutter/material.dart';
import '../../services/worker_service.dart';
import '../../services/supabase_auth_service.dart';
import 'worker_chat_conversation.dart';

class WorkerChatList extends StatefulWidget {
  const WorkerChatList({super.key});

  @override
  State<WorkerChatList> createState() => _WorkerChatListState();
}

class _WorkerChatListState extends State<WorkerChatList> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final user = SupabaseAuthService.getCurrentUser();
      if (user == null) return;

      _workerId = user.id;
      final chats = await WorkerService.getWorkerChats(user.id);

      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $e')),
        );
      }
    }
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
        title: const Text('Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChats,
        child: _chats.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active chats',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chats will appear here once you accept job requests',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  return _buildChatCard(_chats[index]);
                },
              ),
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    final startDate = DateTime.tryParse(chat['start_date'] ?? '');
    final status = chat['status'] ?? 'unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: chat['household_picture'] != null
              ? NetworkImage(chat['household_picture'])
              : null,
          child: chat['household_picture'] == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          chat['household_name'] ?? 'Unknown Household',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${chat['service_type'] ?? 'Unknown'}'),
            if (startDate != null)
              Text('Date: ${startDate.toString().split(' ')[0]}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(
                status.toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: _getStatusColor(status),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerChatConversation(
                jobId: chat['job_id'],
                householdId: chat['household_id'],
                householdName: chat['household_name'] ?? 'Unknown',
                serviceType: chat['service_type'] ?? 'Unknown',
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green.withOpacity(0.2);
      case 'ongoing':
        return Colors.blue.withOpacity(0.2);
      case 'completed':
        return Colors.purple.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }
}
