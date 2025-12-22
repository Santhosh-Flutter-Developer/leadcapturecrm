// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  @override
  bool operator ==(covariant ChatModel other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.createdBy == createdBy &&
        listEquals(other.participants, participants) &&
        other.title == title &&
        other.description == description &&
        other.isGroupChat == isGroupChat &&
        other.lastMessage == lastMessage &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        createdBy.hashCode ^
        participants.hashCode ^
        title.hashCode ^
        description.hashCode ^
        isGroupChat.hashCode ^
        lastMessage.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class MessagesModel {
  final String? uid;
  final String senderId;
  final List<String> receiverId;
  final String message;
  final List<FileModel> attachments;
  final bool edited;
  final List<MessagesEditHistory> editHistory;
  final String? replyFor;
  final List<String> seenBy;
  final DateTime? timestamp;
  final Map<String, List<String>> reactions;
  final bool isPinned;
  final String searchKeywords;

  MessagesModel({
    this.uid,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.edited = false,
    this.replyFor,
    this.editHistory = const [],
    this.seenBy = const [],
    required this.attachments,
    this.timestamp,
    this.reactions = const {},
    this.isPinned = false,
    this.searchKeywords = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'seenBy': seenBy,
      'edited': edited,
      'editHistory': [],
      'replyFor': replyFor,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'reactions': reactions,
      'isPinned': isPinned,
      'searchKeywords': [
        message,
        attachments.map((x) => x.name).toList().join(', '),
      ].join(', '),
    };
  }

  Map<String, dynamic> toEditMap() {
    return <String, dynamic>{
      'message': message,
      'edited': edited,
      'editHistory': FieldValue.arrayUnion([
        ...editHistory.map((x) => x.toMap()),
      ]),
      'attachments': FieldValue.arrayUnion([
        ...attachments.map((x) => x.toMap()),
      ]),
    };
  }

  factory MessagesModel.fromMap(Map<String, dynamic> map) {
    return MessagesModel(
      uid: map['uid'],
      senderId: map['senderId'] as String,
      receiverId: (map['receiverId'] as List).map((e) => e.toString()).toList(),
      message: map['message'] as String,
      attachments: (map['attachments'] as List)
          .map<FileModel>((x) => FileModel.fromMap(x as Map<String, dynamic>))
          .toList(),
      seenBy: (map['seenBy'] as List).map((e) => e.toString()).toList(),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : null,
      replyFor: map['replyFor'],
      edited: map['edited'] ?? false,
      reactions: map['reactions'] != null
          ? Map<String, List<String>>.from(
              (map['reactions'] as Map).map(
                (key, value) => MapEntry(key, List<String>.from(value ?? [])),
              ),
            )
          : {},
      isPinned: map['isPinned'] ?? false,
    );
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
