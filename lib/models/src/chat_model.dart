import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/models.dart';

class ChatModel {
  final String? uid;
  final String createdBy;
  final List<String> participants;
  final String participantsKey;
  final String? title;
  final String? description;
  final bool isGroupChat;
  final LastMessageModel? lastMessage;
  final bool isPinned;
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatModel({
    this.uid,
    required this.createdBy,
    required this.participants,
    required this.participantsKey,
    this.title,
    this.description,
    this.isGroupChat = false,
    this.lastMessage,
    required this.isPinned,
    required this.isFavorite,
    this.createdAt,
    this.updatedAt,
  });

  ChatModel copyWith({
    String? uid,
    String? createdBy,
    List<String>? participants,
    String? participantsKey,
    String? title,
    String? description,
    bool? isGroupChat,
    LastMessageModel? lastMessage,
    Map<String, List<String>>? reactions,
    bool? isPinned,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      participantsKey: participantsKey ?? this.participantsKey,
      title: title ?? this.title,
      description: description ?? this.description,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      lastMessage: lastMessage ?? this.lastMessage,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'createdBy': createdBy,
      'participants': participants,
      'participantsKey': participantsKey,
      'title': title,
      'description': description,
      'isGroupChat': isGroupChat,
      'lastMessage': lastMessage?.toMap(),
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ChatModel.fromMap(String uid, Map<String, dynamic> map) {
    return ChatModel(
      uid: uid,
      createdBy: map['createdBy'] is String ? map['createdBy'] as String : '',
      participants: map['participants'] != null && map['participants'] is List
          ? List<String>.from(
              (map['participants'] as List).map((e) => e.toString()),
            )
          : [],
      participantsKey:
          map['participantsKey'] != null && map['participantsKey'] is String
          ? map['participantsKey'] as String
          : '',
      title: map['title'] != null && map['title'] is String
          ? map['title'] as String
          : null,
      description: map['description'] != null && map['description'] is String
          ? map['description'] as String
          : null,
      isGroupChat: map['isGroupChat'] is bool
          ? map['isGroupChat'] as bool
          : false,
      lastMessage:
          map['lastMessage'] != null &&
              map['lastMessage'] is Map<String, dynamic>
          ? LastMessageModel.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
      isPinned: map['isPinned'] != null ? map['isPinned'] as bool : false,
      isFavorite: map['isFavorite'] != null ? map['isFavorite'] as bool : false,
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatModel.fromJson(String uid, String source) =>
      ChatModel.fromMap(uid, json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ChatModel(uid: $uid, createdBy: $createdBy, participants: $participants, title: $title, description: $description, isGroupChat: $isGroupChat, lastMessage: $lastMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class MessagesModel {
  final String? uid;
  final String chatId;
  final String senderId;
  final String? senderName;

  String message;

  final List<String> receiverId;

  final List<FileModel> attachments;

  final bool edited;
  final List<MessagesEditHistory> editHistory;

  final String? replyFor;
  final String? replyForMessageId;

  final String? forwardFrom;
  final String? forwardFromMessageId;
  final String? forwardFromChatId;

  final List<String> seenBy;

  final Map<String, List<String>> reactions;

  final bool deleted;

  final bool isPinned;
  final DateTime? pinnedTimeStamp;

  final DateTime timestamp;

  final List<String> searchKeywords;

  MessagesModel({
    this.uid,
    required this.chatId,
    required this.senderId,
    this.senderName,
    required this.receiverId,
    required this.message,
    this.attachments = const [],
    this.edited = false,
    this.editHistory = const [],
    this.replyFor,
    this.replyForMessageId,
    this.forwardFrom,
    this.forwardFromMessageId,
    this.forwardFromChatId,
    this.seenBy = const [],
    this.reactions = const {},
    this.deleted = false,
    this.isPinned = false,
    this.pinnedTimeStamp,
    DateTime? timestamp,
    this.searchKeywords = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  // ---------------- MAP ----------------

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'edited': edited,
      'editHistory': editHistory.map((x) => x.toMap()).toList(),
      'replyFor': replyFor,
      'replyForMessageId': replyForMessageId,
      'forwardFrom': forwardFrom,
      'forwardFromMessageId': forwardFromMessageId,
      'forwardFromChatId': forwardFromChatId,
      'seenBy': seenBy,
      'reactions': reactions,
      'deleted': deleted,
      'isPinned': isPinned,
      'pinnedTimeStamp': pinnedTimeStamp?.millisecondsSinceEpoch,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'searchKeywords': [
        ...buildSearchKeywords(message),
        ...attachments.expand((f) => buildSearchKeywords(f.name)),
      ],
    };
  }

  // ---------------- FROM MAP ----------------

  factory MessagesModel.fromMap(String id, Map<String, dynamic> map) {
    return MessagesModel(
      uid: id,
      chatId: map['chatId'],
      senderId: map['senderId'],
      senderName: map['senderName'],
      receiverId: List<String>.from(map['receiverId'] ?? []),
      message: map['message'],
      attachments: (map['attachments'] as List? ?? [])
          .map((e) => FileModel.fromMap(e))
          .toList(),
      edited: map['edited'] ?? false,
      replyFor: map['replyFor'],
      replyForMessageId: map['replyForMessageId'],
      forwardFrom: map['forwardFrom'],
      forwardFromMessageId: map['forwardFromMessageId'],
      forwardFromChatId: map['forwardFromChatId'],
      seenBy: List<String>.from(map['seenBy'] ?? []),
      reactions: map['reactions'] != null
          ? Map<String, List<String>>.from(
              (map['reactions'] as Map).map(
                (k, v) => MapEntry(k, List<String>.from(v)),
              ),
            )
          : {},
      deleted: map['deleted'] ?? false,
      isPinned: map['isPinned'] ?? false,
      pinnedTimeStamp: map['pinnedTimeStamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['pinnedTimeStamp'])
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  // ---------------- EDIT ----------------

  Map<String, dynamic> toEditMap() {
    return {
      'message': message,
      'edited': true,
      'attachments': FieldValue.arrayUnion(
        attachments.map((x) => x.toMap()).toList(),
      ),
      'editHistory': FieldValue.arrayUnion(
        editHistory.map((x) => x.toMap()).toList(),
      ),
    };
  }
}

class LastMessageModel {
  final String senderId;
  final String message;
  final DateTime? timestamp;
  LastMessageModel({
    required this.senderId,
    required this.message,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderId': senderId,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory LastMessageModel.fromMap(Map<String, dynamic> map) {
    return LastMessageModel(
      senderId: map['senderId'] as String,
      message: map['message'] as String,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : null,
    );
  }

  factory LastMessageModel.empty() {
    return LastMessageModel(senderId: '', message: '');
  }
}

class MessagesEditHistory {
  final String message;
  final DateTime? timestamp;
  MessagesEditHistory({required this.message, this.timestamp});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory MessagesEditHistory.fromMap(Map<String, dynamic> map) {
    return MessagesEditHistory(
      message: map['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}

List<String> buildSearchKeywords(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toSet() // avoid duplicates
      .toList();
}
