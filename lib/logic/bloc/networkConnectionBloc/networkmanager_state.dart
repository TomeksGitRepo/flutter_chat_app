part of 'networkmanager_bloc.dart';

@immutable
abstract class NetworkmanagerState {}

class NetworkmanagerInitial extends NetworkmanagerState {}

class NetworkConnectionOnline extends NetworkmanagerState {}

class NetworkConnectionOffline extends NetworkmanagerState {}

class CheckingConnection extends NetworkmanagerState {}
