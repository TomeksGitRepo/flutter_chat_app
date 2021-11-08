import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/routes.dart';
import 'package:xxxx/widgets/chat/user_thumbnail.dart';

class CreateIndividualUserChatScreen extends StatefulWidget {
  CreateIndividualUserChatScreen();

  @override
  _CreateIndividualUserChatScreen createState() =>
      _CreateIndividualUserChatScreen();
}

class _CreateIndividualUserChatScreen
    extends State<CreateIndividualUserChatScreen> {
  List<dynamic> users = [];

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    List<Map<String, dynamic>> usersFromDB = [];

    var streamUser = FirebaseFirestore.instance.collection('users').snapshots();

    streamUser.forEach((element) {
      element.docs.forEach((element) async {
        // print('element.data is: ${element.data}');
        // print('element.documentID is: ${element.documentID}');
        // print('usersChats.length == ${usersChats.length}');

        var elemntCopy = element.data();
        elemntCopy!['userUID'] = element.id;
        usersFromDB.add(elemntCopy);
        setState(() {
          users = usersFromDB;
        });
      });
    });

    return usersFromDB;
  }

  @override
  void initState() {
    super.initState();
    getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wybierz użytkownika'),
        actions: [
          DropdownButton(
            underline: Container(),
            icon: Icon(Icons.more_vert,
                color: Theme.of(context).primaryIconTheme.color),
            items: [
              DropdownMenuItem(
                child: Container(
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(
                        width: 8,
                      ),
                      Text('Wyloguj'),
                    ],
                  ),
                ),
                value: 'logout',
              )
            ],
            onChanged: (itemIdentifier) {
              if (itemIdentifier == 'logout') {
                BlocProvider.of<UserBloc>(context).add(LogoutUser(context));
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        Text(
          'Wybierz użytkownika:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return UserThumbnail(
                  userName: users[index]['username'],
                  userUID: users[index]['userUID'],
                );
              }),
        ),
      ]),
    );
  }
}
