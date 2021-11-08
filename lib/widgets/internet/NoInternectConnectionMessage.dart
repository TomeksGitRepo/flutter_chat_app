import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/networkConnectionBloc/networkmanager_bloc.dart';
import 'package:xxxx/logic/managers/NetworkConnectionManager.dart';

class NoInternetConnectionMessage extends StatelessWidget {
  const NoInternetConnectionMessage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.white70,
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Icon(Icons.mobile_off, color: Colors.blue[100]),
                Text(
                  'Brak połączenia z internetem. Aplikacja nie działa poprawnie bez połączenia z internetem.',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  child: Text(
                    'Sprawdź połączenie',
                    style: TextStyle(color: Colors.blue[10]),
                  ),
                  onPressed: () async {
                    //TODO add posibility user to check connection manualy
                    BlocProvider.of<NetworkmanagerBloc>(context)
                        .add(CheckConnectionEvent());
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
