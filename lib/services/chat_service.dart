import '../models/chat_modal.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Sample data for demonstration
  final List<ChatMessage> _sampleMessages = [
    ChatMessage(
      id: '1',
      senderId: 'emp1',
      senderName: 'John Doe',
      receiverId: '1',
      content: 'Hello, are you available for cleaning this weekend?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: MessageType.text,
    ),
    ChatMessage(
      id: '2',
      senderId: '1',
      senderName: 'Alice Johnson',
      receiverId: 'emp1',
      content: 'Yes, I am available. What time would work for you?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: MessageType.text,
      isRead: true,
    ),
  ];

  final List<Chat> _sampleChats = [
    Chat(
      id: 'chat1',
      participants: ['emp1', '1'],
      lastMessage: 'Yes, I am available. What time would work for you?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
      lastSenderId: '1',
      unreadCounts: {'emp1': 1, '1': 0},
    ),
  ];

  Future<List<Chat>> getChatsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sampleChats
        .where((chat) => chat.participants.contains(userId))
        .toList();
  }

  Future<List<ChatMessage>> getMessagesForChat(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _sampleMessages;
  }

  Future<bool> sendMessage(ChatMessage message) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sampleMessages.add(message);

    // Update chat with new last message
    final chatIndex = _sampleChats.indexWhere((chat) =>
        chat.participants.contains(message.senderId) &&
        chat.participants.contains(message.receiverId));

    if (chatIndex != -1) {
      final chat = _sampleChats[chatIndex];
      final updatedUnreadCounts = Map<String, int>.from(chat.unreadCounts);
      updatedUnreadCounts[message.receiverId] =
          (updatedUnreadCounts[message.receiverId] ?? 0) + 1;

      _sampleChats[chatIndex] = Chat(
        id: chat.id,
        participants: chat.participants,
        lastMessage: message.content,
        lastMessageTime: message.timestamp,
        lastSenderId: message.senderId,
        unreadCounts: updatedUnreadCounts,
      );
    }

    return true;
  }

  // New method with named parameters for compatibility
  Future<bool> sendMessageWithParams({
    required String hireRequestId,
    required String message,
    required bool isFromHelper,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final chatMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: isFromHelper ? 'helper_1' : 'employer_1',
      senderName: isFromHelper ? 'Helper' : 'Employer',
      receiverId: isFromHelper ? 'employer_1' : 'helper_1',
      content: message,
      timestamp: DateTime.now(),
      type: attachmentUrl != null
          ? (attachmentType == 'image' ? MessageType.image : MessageType.file)
          : MessageType.text,
      isFromHelper: isFromHelper,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );

    return await sendMessage(chatMessage);
  }

  Future<bool> markMessageAsRead(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _sampleMessages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      final message = _sampleMessages[index];
      _sampleMessages[index] = ChatMessage(
        id: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        receiverId: message.receiverId,
        content: message.content,
        timestamp: message.timestamp,
        type: message.type,
        isRead: true,
        attachmentUrl: message.attachmentUrl,
      );
      return true;
    }
    return false;
  }

  Future<Chat?> getChatBetweenUsers(String userId1, String userId2) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _sampleChats.firstWhere((chat) =>
          chat.participants.contains(userId1) &&
          chat.participants.contains(userId2));
    } catch (e) {
      return null;
    }
  }

  Future<Chat> createChat(List<String> participants) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final chat = Chat(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      participants: participants,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      lastSenderId: '',
      unreadCounts: {for (String participant in participants) participant: 0},
    );

    _sampleChats.add(chat);
    return chat;
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    // Return a stream that emits the sample messages
    return Stream.periodic(const Duration(seconds: 1), (i) {
      return _sampleMessages;
    });
  }

  Future<void> markMessagesAsRead(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Mark all messages in the chat as read
    for (int i = 0; i < _sampleMessages.length; i++) {
      final message = _sampleMessages[i];
      _sampleMessages[i] = ChatMessage(
        id: message.id,
        senderId: message.senderId,
        senderName: message.senderName,
        receiverId: message.receiverId,
        content: message.content,
        timestamp: message.timestamp,
        type: message.type,
        isRead: true,
        attachmentUrl: message.attachmentUrl,
        isFromHelper: message.isFromHelper,
        attachmentType: message.attachmentType,
      );
    }
  }
}
