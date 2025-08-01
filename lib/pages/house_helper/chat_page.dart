import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:househelp/models/hire_request.dart';
import '../../models/chat_modal.dart';
import '../../services/chat_service.dart';
import '../../services/file_storage_service.dart';

class ChatPage extends StatefulWidget {
  final HireRequest hireRequest;

  const ChatPage({super.key, required this.hireRequest});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  Stream<List<ChatMessage>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
  }

  void _initializeChat() {
    _messagesStream = _chatService.getMessages(widget.hireRequest.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.markMessagesAsRead(widget.hireRequest.id);
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _chatService.sendMessageWithParams(
      hireRequestId: widget.hireRequest.id,
      message: _messageController.text.trim(),
      isFromHelper: user.uid == widget.hireRequest.helperUid,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _uploadAttachment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show options for media types
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select Media Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Choose Video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      XFile? file;

      switch (result) {
        case 'camera':
          file = await _picker.pickImage(source: ImageSource.camera);
          break;
        case 'gallery':
          file = await _picker.pickImage(source: ImageSource.gallery);
          break;
        case 'video':
          file = await _picker.pickVideo(source: ImageSource.gallery);
          break;
      }

      if (file != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result == 'video' ? 'Video' : 'Image'} selected: ${file.name}',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // TODO: Implement file upload logic here
        try {
          // Show loading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Uploading file...'),
                  ],
                ),
                duration: Duration(seconds: 30),
              ),
            );
          }

          // 1. Upload the file to Firebase Storage
          final String chatId = widget.hireRequest.id;
          final String senderId = user.uid;
          String downloadUrl = await FileStorageService.uploadChatAttachment(
              file, chatId, senderId);

          // 2. Get the download URL and determine file type
          String attachmentType = FileStorageService.getFileType(file.name);

          // 3. Send the message with attachment
          String messageText = '';
          switch (result) {
            case 'image':
              messageText = '📷 Image';
              attachmentType = 'image';
              break;
            case 'video':
              messageText = '🎥 Video';
              attachmentType = 'video';
              break;
            default:
              messageText = '📎 File';
          }

          await _chatService.sendMessageWithParams(
            hireRequestId: widget.hireRequest.id,
            message: messageText,
            isFromHelper: user.uid == widget.hireRequest.helperUid,
            attachmentUrl: downloadUrl,
            attachmentType: attachmentType,
          );

          // Hide loading indicator and show success
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${result == 'video' ? 'Video' : 'Image'} sent successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Hide loading indicator and show error
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to upload ${result == 'video' ? 'video' : 'image'}: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final isHelper = user?.uid == widget.hireRequest.helperUid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(colorScheme, isHelper),
      body: Column(
        children: [
          // Job Info Banner
          _buildJobInfoBanner(colorScheme),

          // Messages List
          Expanded(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_slideAnimation),
              child: StreamBuilder<List<ChatMessage>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return _buildMessagesList(snapshot.data ?? [], isHelper);
                },
              ),
            ),
          ),

          // Message Input
          _buildMessageInput(colorScheme, isHelper),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme, bool isHelper) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hireRequest.workAddress,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            isHelper ? 'House Holder' : widget.hireRequest.helperName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () async {
            // TODO: Implement phone call functionality
            try {
              // Get the phone number from the hire request or user profile
              String phoneNumber = widget.hireRequest.employerPhone;

              if (phoneNumber.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number not available'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              // Clean phone number (remove spaces, dashes, etc.)
              phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

              // Create phone URI
              final Uri phoneUri = Uri(
                scheme: 'tel',
                path: phoneNumber,
              );

              // Check if we can launch the phone dialer
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              } else {
                if (mounted) {
                  // Show dialog with phone number so user can copy it
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Call Employer'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                                'Unable to open phone dialer automatically.'),
                            const SizedBox(height: 8),
                            const Text('Phone number:'),
                            const SizedBox(height: 4),
                            SelectableText(
                              phoneNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to make call: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildJobInfoBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getStatusIcon(), color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job: ${widget.hireRequest.activities.first.replaceAll("_", " ")}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Status: ${widget.hireRequest.statusDisplayText}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '\$${widget.hireRequest.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages, bool isHelper) {
    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Start the conversation!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message, isHelper);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isHelper) {
    final isCurrentUser = (isHelper && message.isFromHelper) ||
        (!isHelper && !message.isFromHelper);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(158, 158, 158, 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachmentUrl != null)
                    _buildAttachmentPreview(message),
                  if (message.message.isNotEmpty)
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isCurrentUser
                          ? const Color.fromRGBO(255, 255, 255, 0.7)
                          : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(ChatMessage message) {
    if (message.attachmentType == 'image') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.attachmentUrl!,
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image)),
              );
            },
          ),
        ),
      );
    } else if (message.attachmentType == 'video') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Video attachment', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.attachmentUrl?.split('/').last ?? 'Attachment',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMessageInput(ColorScheme colorScheme, bool isHelper) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment Button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                onPressed: _uploadAttachment,
              ),
            ),
            const SizedBox(width: 8),

            // Message Input Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send Button
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (widget.hireRequest.status) {
      case HireStatus.pending:
        return Icons.access_time;
      case HireStatus.ongoing:
        return Icons.work;
      case HireStatus.finished:
        return Icons.check_circle;
      case HireStatus.canceled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
