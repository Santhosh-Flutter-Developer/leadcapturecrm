import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/models.dart';

class FeedModel {
  final String? uid;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<FileModel> mediaImages;
  final List<FileModel> attachments;
  final List<TaggedUserModel> taggedUsers;
  final PollModel? poll;
  final List<ReactionModel> reactions;
  final int commentsCount;
  final List<CommentModel>? comments;
  final DateTime createdAt;

  FeedModel({
    this.uid,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    DateTime? createdAt,
    required this.mediaImages,
    required this.attachments,
    required this.taggedUsers,
    required this.reactions,
    this.poll,
    this.commentsCount = 0,
    this.comments,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FeedModel.fromMap(String uid, Map<String, dynamic> map) {
    return FeedModel(
      uid: uid,
      authorId: map['authorId'] != null && map['authorId'] is String
          ? map['authorId']
          : '',
      authorName: map['authorName'] != null && map['authorName'] is String
          ? map['authorName']
          : '',
      authorAvatar: map['authorAvatar'] != null && map['authorAvatar'] is String
          ? map['authorAvatar']
          : '',
      content: map['content'] != null && map['content'] is String
          ? map['content']
          : '',
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      mediaImages: map['mediaImages'] != null
          ? (map['mediaImages'] as List<dynamic>? ?? [])
                .map((x) => FileModel.fromMap(x))
                .toList()
          : [],
      attachments: map['attachments'] != null
          ? (map['attachments'] as List<dynamic>? ?? [])
                .map((x) => FileModel.fromMap(x))
                .toList()
          : [],
      taggedUsers: map['taggedUsers'] != null
          ? (map['taggedUsers'] as List<dynamic>? ?? [])
                .map((x) => TaggedUserModel.fromMap(x))
                .toList()
          : [],
      reactions: map['reactions'] != null
          ? (map['reactions'] as List<dynamic>? ?? [])
                .map((x) => ReactionModel.fromMap(x))
                .toList()
          : [],
      poll: map['poll'] != null ? PollModel.fromMap(map['poll']) : null,
      commentsCount: map['commentsCount'] != null && map['commentsCount'] is int
          ? map['commentsCount']
          : 0,
      comments: map['comments'] != null
          ? (map['comments'] as List<dynamic>? ?? [])
                .map((x) => CommentModel.fromMap(x))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'mediaImages': mediaImages.map((e) => e.toMap()).toList(),
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'taggedUsers': taggedUsers.map((e) => e.toMap()).toList(),
      'reactions': reactions.map((e) => e.toMap()).toList(),
      'poll': poll?.toMap(),
      'commentsCount': commentsCount,
      'comments': comments?.map((e) => e.toMap()).toList(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'mediaImages': mediaImages.map((e) => e.toMap()).toList(),
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'taggedUsers': taggedUsers.map((e) => e.toMap()).toList(),
      'reactions': reactions.map((e) => e.toMap()).toList(),
      'poll': poll?.toMap(),
      'commentsCount': commentsCount,
      'comments': comments?.map((e) => e.toMap()).toList(),
    };
  }
}

class ReactionModel {
  final String userId;
  final String type;

  ReactionModel({required this.userId, required this.type});

  factory ReactionModel.fromMap(Map<String, dynamic> map) {
    return ReactionModel(
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'like',
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'type': type};
  }
}

class TaggedUserModel {
  final String userId;
  final String userName;

  TaggedUserModel({required this.userId, required this.userName});

  factory TaggedUserModel.fromMap(Map<String, dynamic> map) {
    return TaggedUserModel(
      userId: map['userId'] != null && map['userId'] is String
          ? map['userId']
          : '',
      userName: map['userName'] != null && map['userName'] is String
          ? map['userName']
          : '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'userName': userName};
  }
}

class PollOption {
  final String optionId;
  final String title;
  int votes;

  PollOption({required this.optionId, required this.title, this.votes = 0});

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      optionId: map['optionId'],
      title: map['title'],
      votes: map['votes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'optionId': optionId, 'title': title, 'votes': votes};
  }
}

class PollModel {
  final String pollId;
  final String question;
  final List<PollOption> options;

  PollModel({
    required this.pollId,
    required this.question,
    required this.options,
  });

  factory PollModel.fromMap(Map<String, dynamic> map) {
    return PollModel(
      pollId: map['pollId'] ?? '',
      question: map['question'] ?? '',
      options: (map['options'] as List<dynamic>? ?? [])
          .map((x) => PollOption.fromMap(x))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pollId': pollId,
      'question': question,
      'options': options.map((e) => e.toMap()).toList(),
    };
  }
}

class CommentModel {
  final String commentId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['commentId'] != null && map['commentId'] is String
          ? map['commentId']
          : '',
      authorId: map['authorId'] != null && map['authorId'] is String
          ? map['authorId']
          : '',
      authorName: map['authorName'] != null && map['authorName'] is String
          ? map['authorName']
          : '',
      authorAvatar: map['authorAvatar'] != null && map['authorAvatar'] is String
          ? map['authorAvatar']
          : '',
      content: map['content'] != null && map['content'] is String
          ? map['content']
          : '',
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
