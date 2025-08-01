class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;
  final String? attachmentUrl;
  final bool isFromHelper;
  final String? attachmentType;

  // Add getter for backwards compatibility
  String get message => content;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead = false,
    this.attachmentUrl,
    this.isFromHelper = false,
    this.attachmentType,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      isRead: map['isRead'] ?? false,
      attachmentUrl: map['attachmentUrl'],
      isFromHelper: map['isFromHelper'] ?? false,
      attachmentType: map['attachmentType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'isFromHelper': isFromHelper,
      'attachmentType': attachmentType,
    };
  }
}

enum MessageType { text, image, file, system }

class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastSenderId;
  final Map<String, int> unreadCounts;

  Chat({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderId,
    required this.unreadCounts,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          DateTime.tryParse(map['lastMessageTime'] ?? '') ?? DateTime.now(),
      lastSenderId: map['lastSenderId'] ?? '',
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastSenderId': lastSenderId,
      'unreadCounts': unreadCounts,
    };
  }
}
