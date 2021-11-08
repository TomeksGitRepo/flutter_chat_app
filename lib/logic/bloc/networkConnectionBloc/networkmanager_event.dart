part of 'networkmanager_bloc.dart';

@immutable
abstract class NetworkmanagerEvent {}

class ApplicationOnlineEvent extends NetworkmanagerEvent {}

class ApplicationOfflineEvent extends NetworkmanagerEvent {}

class CheckConnectionEvent extends NetworkmanagerEvent {}
