class NotificationModel {
  final String? uid;
  final String title;
  final String message;
  final List<String> toFcms;
  final List<String> toUids;
  final String? senderId;
  final String? type;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
  NotificationModel({
    this.uid,
    required this.title,
    required this.message,
    required this.toFcms,
    required this.toUids,
    this.senderId,
    this.type,
    required this.payload,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'message': message,
      'toFcms': toFcms,
      'toUids': toUids,
      'senderId': senderId,
      'type': type,
      'payload': payload,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory NotificationModel.fromMap(String uid, Map<String, dynamic> map) {
    return NotificationModel(
      uid: uid,
      title: map['title'] != null && map['title'] is String ? map['title'] : '',
      message: map['message'] != null && map['message'] is String
          ? map['message']
          : '',
      toFcms: map['toFcms'] != null && map['toFcms'] is List
          ? (map['toFcms'] as List).map((e) => e.toString()).toList()
          : [],
      toUids: map['toUids'] != null && map['toUids'] is List
          ? (map['toUids'] as List).map((e) => e.toString()).toList()
          : [],
      senderId: map['senderId'] != null && map['senderId'] is String
          ? map['senderId']
          : null,
      type: map['type'] != null && map['type'] is String ? map['type'] : null,
      payload: map['payload'] != null && map['payload'] is Map<String, dynamic>
          ? map['payload'] as Map<String, dynamic>
          : {},
      createdAt: map['createdAt'] != null && map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}
