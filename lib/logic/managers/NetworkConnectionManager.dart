import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/networkConnectionBloc/networkmanager_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';

class NetworkConnectionManager extends StatefulWidget {
  late BuildContext _parentContext;

  @override
  _NetworkConnectionManagerState createState() =>
      _NetworkConnectionManagerState();
}

class _NetworkConnectionManagerState extends State<NetworkConnectionManager> {
  Timer? _timer;
  static const timeout = Duration(minutes: 1);

  checkFirebaseNetworkConnection() async {
    BlocProvider.of<NetworkmanagerBloc>(context).add(CheckConnectionEvent());
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(timeout, (Timer t) {
      checkFirebaseNetworkConnection();
    });
    checkFirebaseNetworkConnection();
  }

  @override
  dispose() {
    _timer!.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
