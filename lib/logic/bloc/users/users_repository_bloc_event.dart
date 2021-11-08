part of 'users_repository_bloc.dart';

@immutable
abstract class UsersRepositoryBlocEvent {}

class GetUserInfo extends UsersRepositoryBlocEvent {
  String? email;
  String? uid;

  GetUserInfo({
    this.email,
    this.uid,
  });
}
