part of 'userbloc_bloc.dart';

abstract class UserblocState {}

class UserblocInitial extends UserblocState {}

class UserLoggedOut extends UserblocState {}

class UserData extends UserblocState {
  MyUser.User userData;

  UserData(
    this.userData,
  );

  Map<String, dynamic> toMap() {
    return {
      'userData': userData.toMap(),
    };
  }

  String toJson() => json.encode(toMap());

  factory UserData.fromJson(String source) =>
      UserData.fromMap(json.decode(source));

  @override
  String toString() => 'UserData(userData: $userData)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is UserData && o.userData == userData;
  }

  @override
  int get hashCode => userData.hashCode;

  UserData? copyWith({
    MyUser.User? userData,
  }) {
    return UserData(
      userData ?? this.userData,
    );
  }

  factory UserData.fromMap(Map<String, dynamic>? map) {
    if (map == null)
      return UserData.fromJson(
          map.toString()); //TODO this will sooner or later fail

    return UserData(
      MyUser.User.fromMap(map['userData']),
    );
  }
}
