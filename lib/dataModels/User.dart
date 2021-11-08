import 'dart:convert';
import 'package:hive/hive.dart';

part 'User.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  String? userUID;
  @HiveField(1)
  String? email;
  @HiveField(2)
  String? username;
  @HiveField(3)
  String? userFirebaseAuthToken;
  @HiveField(4)
  bool? isAPPMember = false;
  @HiveField(5)
  String? memberCompanyName = "";
  @HiveField(6)
  String? userAvatarURL;
  @HiveField(7)
  List<String>? bannedUsers;

  User(
      {this.email,
      this.username,
      this.userFirebaseAuthToken,
      this.isAPPMember,
      this.memberCompanyName,
      this.userAvatarURL,
      this.userUID,
      this.bannedUsers});

  Map<String, dynamic> toMap() {
    return {
      'userUID': userUID,
      'email': email,
      'username': username,
      'userFirebaseAuthToken': userFirebaseAuthToken,
      'isAPPMember': isAPPMember,
      'memberCompanyName': memberCompanyName,
      'userAvatarURL': userAvatarURL,
      'bannedUsers': bannedUsers,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userUID: map['userUID'],
      email: map['email'],
      username: map['username'],
      userFirebaseAuthToken: map['userFirebaseAuthToken'],
      isAPPMember: map['isAPPMember'],
      memberCompanyName: map['MemberCompanyName'],
      userAvatarURL: map['user_avatar_image_url'],
      bannedUsers: map['bannedUsers'] == null
          ? []
          : List<String>.from(map['bannedUsers']),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(Map<String, dynamic> source) => User.fromMap(source);
}
