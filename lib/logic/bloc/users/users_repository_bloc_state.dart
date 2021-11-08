part of 'users_repository_bloc.dart';

@immutable
abstract class UsersRepositoryBlocState {}

class UsersRepositoryBlocInitial extends UsersRepositoryBlocState {}

class UserInfoReturnedFromCache extends UsersRepositoryBlocState {
  final User userFound;

  UserInfoReturnedFromCache(this.userFound);
}

class UsersInfoLoadedFromStorage extends UsersRepositoryBlocState {}
