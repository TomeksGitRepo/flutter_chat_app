import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:xxxx/dataModels/Message.dart';

import 'Timestamp.dart';

part 'Chat.g.dart';

@HiveType(typeId: 1)
class Chat {
  @HiveField(0)
  List<String> adminsUID;
  @HiveField(1)
  String chatName;
  @HiveField(2)
  bool isGroupChat;
  @HiveField(3)
  Map<String, Map<String, dynamic>> usersInvolvedUID;
  @HiveField(4)
  String chatID;
  @HiveField(5)
  Map<String, dynamic>? lastMessage;
  @HiveField(6)
  List<Message>? messages = [];
  @HiveField(7)
  List<String>? usersBannedByAdminUID;

  Chat({
    required this.adminsUID,
    required this.chatName,
    required this.isGroupChat,
    required this.usersInvolvedUID,
    required this.chatID,
    this.lastMessage,
    this.messages,
    this.usersBannedByAdminUID,
  });

  Chat copyWith({
    List<String>? adminsUID,
    String? chatName,
    bool? isGroupChat,
    Map<String, Map<String, dynamic>>? usersInvolvedUID,
    String? chatID,
    Map<String, dynamic>? lastMessage,
    List<Message>? messages,
    List<String>? usersBannedByAdminUID,
  }) {
    return Chat(
      adminsUID: adminsUID ?? this.adminsUID,
      chatName: chatName ?? this.chatName,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      usersInvolvedUID: usersInvolvedUID ?? this.usersInvolvedUID,
      chatID: chatID ?? this.chatID,
      lastMessage: lastMessage ?? this.lastMessage,
      messages: messages ?? this.messages,
      usersBannedByAdminUID:
          usersBannedByAdminUID ?? this.usersBannedByAdminUID,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminsUID': adminsUID,
      'chatName': chatName,
      'isGroupChat': isGroupChat,
      'usersInvolvedUID': usersInvolvedUID,
      'chatID': chatID,
      'lastMessage': lastMessage,
      'messages': messages?.map((x) => x.toMap()).toList(),
      'usersBannedByAdminUID': usersBannedByAdminUID,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    //TODO get last message from map messages
    List<Message> messagesList = List<Message>.from(map['messages'] == null
        ? []
        : map['messages'].map((x) => Message.fromMap(x)));

    return Chat(
      adminsUID: List<String>.from(map['adminsUID']),
      chatName: map['chatName'],
      isGroupChat: map['isGroupChat'],
      usersInvolvedUID:
          Map<String, Map<String, dynamic>>.from(map['usersInvolvedUID']),
      chatID: map['chatID'],
      messages: messagesList,
      usersBannedByAdminUID: map['usersBannedByAdminUID'] != null
          ? List<String>.from(map['usersBannedByAdminUID'])
          : null,
      lastMessage: map['lastMessage'] == null
          ? null
          : Map<String, dynamic>.fromEntries(
              (map['lastMessage'] as Map<String, dynamic>).entries.map(
                (entry) {
                  if (entry.value is cf.Timestamp) {
                    var myTimestamp = Timestamp.fromMillisecondsSinceEpoch(
                        entry.value.millisecondsSinceEpoch);
                    return MapEntry(entry.key, myTimestamp);
                  }
                  return MapEntry(entry.key, entry.value);
                },
              ),
            ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Chat.fromJson(String source) => Chat.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Chat(adminsUID: $adminsUID, chatName: $chatName, isGroupChat: $isGroupChat, usersInvolvedUID: $usersInvolvedUID, chatID: $chatID, lastMessage: $lastMessage, messages: $messages, usersBannedByAdminUID: $usersBannedByAdminUID)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Chat &&
        listEquals(other.adminsUID, adminsUID) &&
        other.chatName == chatName &&
        other.isGroupChat == isGroupChat &&
        mapEquals(other.usersInvolvedUID, usersInvolvedUID) &&
        other.chatID == chatID &&
        mapEquals(other.lastMessage, lastMessage) &&
        listEquals(other.messages, messages) &&
        listEquals(other.usersBannedByAdminUID, usersBannedByAdminUID);
  }

  @override
  int get hashCode {
    return adminsUID.hashCode ^
        chatName.hashCode ^
        isGroupChat.hashCode ^
        usersInvolvedUID.hashCode ^
        chatID.hashCode ^
        lastMessage.hashCode ^
        messages.hashCode ^
        usersBannedByAdminUID.hashCode;
  }
}
