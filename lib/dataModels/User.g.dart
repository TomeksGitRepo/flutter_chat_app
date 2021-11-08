// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'User.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      email: fields[1] as String?,
      username: fields[2] as String?,
      userFirebaseAuthToken: fields[3] as String?,
      isAPPMember: fields[4] as bool?,
      memberCompanyName: fields[5] as String?,
      userAvatarURL: fields[6] as String?,
      userUID: fields[0] as String?,
      bannedUsers: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userUID)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.userFirebaseAuthToken)
      ..writeByte(4)
      ..write(obj.isAPPMember)
      ..writeByte(5)
      ..write(obj.memberCompanyName)
      ..writeByte(6)
      ..write(obj.userAvatarURL)
      ..writeByte(7)
      ..write(obj.bannedUsers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
