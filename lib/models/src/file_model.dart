class FileModel {
  final String name;
  final String url;
  final int size;
  final String extension;
  final String mimeType;
  final DateTime? createdAt;

  FileModel({
    required this.name,
    required this.url,
    required this.size,
    required this.extension,
    required this.mimeType,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'url': url,
      'size': size,
      'extension': extension,
      'mimeType': mimeType,
      "createdAt": createdAt?.millisecondsSinceEpoch,
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      name: map['name'] != null && map['name'] is String ? map['name'] : '',
      url: map['url'] != null && map['url'] is String ? map['url'] : '',
      size: map['size'] is int
          ? map['size']
          : int.tryParse(map['size']?.toString() ?? '0') ?? 0,
      extension: map['extension'] != null && map['extension'] is String
          ? map['extension']
          : '',
      mimeType: map['mimeType'] != null && map['mimeType'] is String
          ? map['mimeType']
          : '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }
}
