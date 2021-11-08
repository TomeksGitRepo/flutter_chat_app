// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Chat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 1;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      adminsUID: (fields[0] as List).cast<String>(),
      chatName: fields[1] as String,
      isGroupChat: fields[2] as bool,
      usersInvolvedUID: (fields[3] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map).cast<String, dynamic>())),
      chatID: fields[4] as String,
      lastMessage: (fields[5] as Map?)?.cast<String, dynamic>(),
      messages: (fields[6] as List?)?.cast<Message>(),
      usersBannedByAdminUID: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.adminsUID)
      ..writeByte(1)
      ..write(obj.chatName)
      ..writeByte(2)
      ..write(obj.isGroupChat)
      ..writeByte(3)
      ..write(obj.usersInvolvedUID)
      ..writeByte(4)
      ..write(obj.chatID)
      ..writeByte(5)
      ..write(obj.lastMessage)
      ..writeByte(6)
      ..write(obj.messages)
      ..writeByte(7)
      ..write(obj.usersBannedByAdminUID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
