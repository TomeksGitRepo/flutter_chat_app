part of 'userbloc_bloc.dart';

class UserblocEvent {}

class GetUserData extends UserblocEvent {
  String email;

  GetUserData(this.email);
}

class CheckUserTokenAndOS extends UserblocEvent {}

class LogoutUser extends UserblocEvent {
  BuildContext context;

  LogoutUser(this.context);
}
