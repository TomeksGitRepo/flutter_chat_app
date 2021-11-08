import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

part 'networkmanager_event.dart';
part 'networkmanager_state.dart';

class NetworkmanagerBloc
    extends Bloc<NetworkmanagerEvent, NetworkmanagerState> {
  NetworkmanagerBloc() : super(NetworkmanagerInitial());

  Future<NetworkmanagerState> checkFirebaseNetworkConnection() async {
    try {
      QuerySnapshot checingNetworkConnection = await FirebaseFirestore.instance
          .collection('checkingNetworkConnection')
          .get(GetOptions(source: Source.server));
      return Future.value(NetworkConnectionOnline());
    } catch (error) {
      print('error in getQueryFromDb is: $error');
      return Future.value(NetworkConnectionOffline());
    }
  }

  @override
  Stream<NetworkmanagerState> mapEventToState(
    NetworkmanagerEvent event,
  ) async* {
    if (event is ApplicationOnlineEvent) {
      yield NetworkConnectionOnline();
    }
    if (event is ApplicationOfflineEvent) {
      yield NetworkConnectionOffline();
    }
    if (event is CheckConnectionEvent) {
      var checkingNetworkConnectionResult =
          await checkFirebaseNetworkConnection();
      if (checkingNetworkConnectionResult is NetworkConnectionOnline) {
        yield checkingNetworkConnectionResult;
      }
      if (checkingNetworkConnectionResult is NetworkConnectionOffline) {
        yield checkingNetworkConnectionResult;
      }
    }
  }
}
