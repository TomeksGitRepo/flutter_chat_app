import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:xxxx/dataModels/Timestamp.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;

part 'Message.g.dart';

@HiveType(typeId: 3)
class Message {
  @HiveField(0)
  String? attachedImageURL;
  @HiveField(1)
  Timestamp createdAt;
  @HiveField(2)
  String text;
  @HiveField(3)
  String userName;
  @HiveField(4)
  String userUID;

  Message({
    this.attachedImageURL,
    required this.createdAt,
    required this.text,
    required this.userName,
    required this.userUID,
  });

  Message copyWith({
    String? attachedImageURL,
    Timestamp? createdAt,
    String? text,
    String? userName,
    String? userUID,
  }) {
    return Message(
      attachedImageURL: attachedImageURL ?? this.attachedImageURL,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      userName: userName ?? this.userName,
      userUID: userUID ?? this.userUID,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attachedImageURL': attachedImageURL,
      'createdAt': createdAt.toMap(),
      'text': text,
      'userName': userName,
      'userUID': userUID,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      attachedImageURL: map['attachedImageURL'],
      createdAt: Timestamp.fromMillisecondsSinceEpoch(
          (map['createdAt'] as cf.Timestamp).millisecondsSinceEpoch),
      text: map['text'],
      userName: map['userName'],
      userUID: map['userUID'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Message(attachedImageURL: $attachedImageURL, createdAt: $createdAt, text: $text, userName: $userName, userUID: $userUID)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.attachedImageURL == attachedImageURL &&
        other.createdAt == createdAt &&
        other.text == text &&
        other.userName == userName &&
        other.userUID == userUID;
  }

  @override
  int get hashCode {
    return attachedImageURL.hashCode ^
        createdAt.hashCode ^
        text.hashCode ^
        userName.hashCode ^
        userUID.hashCode;
  }
}
