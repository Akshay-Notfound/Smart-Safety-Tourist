import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isAuthority;
  final bool isEdited;
  final Map<String, String> reactions;
  final String? senderProfileUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isAuthority = false,
    this.isEdited = false,
    this.reactions = const {},
    this.senderProfileUrl,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isAuthority: map['isAuthority'] ?? false,
      isEdited: map['isEdited'] ?? false,
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      senderProfileUrl: map['senderProfileUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAuthority': isAuthority,
      'isEdited': isEdited,
      'reactions': reactions,
      'senderProfileUrl': senderProfileUrl,
    };
  }
}
