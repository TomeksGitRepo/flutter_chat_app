import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/widgets/chat/user_thumbnail.dart';

class AddingUserToChatScreen extends StatefulWidget {
  final arguments;

  AddingUserToChatScreen({this.arguments});

  @override
  _AddingUserToChatState createState() => _AddingUserToChatState();
}

class _AddingUserToChatState extends State<AddingUserToChatScreen> {
  List<dynamic> users = [];
  Map<String, dynamic> usersInvoledInChat = new Map();
  var streamUser = FirebaseFirestore.instance.collection('users').snapshots();
  Stream<DocumentSnapshot>? chatsUsers;

  Future<void> getAllUsers() async {
    print('started getAllUsers function');

    var tempUsersFromDB = await getAllUsersFromDB();

    setState(() {
      users = tempUsersFromDB;
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsersFromDB() async {
    List<Map<String, dynamic>> usersFromDB = [];
    await for (var element in streamUser) {
      for (var doc in element.docs) {
        var elemntCopy = doc.data();
        elemntCopy!['userUID'] = doc.id;
        usersFromDB.add(elemntCopy);
        setState(() {
          users = usersFromDB;
        });
      }
    }
    return usersFromDB;
  }

  Future<List<Map<String, dynamic>>> getUsersInvoledInChat(
      String chatID) async {
    print('started getUsersInvoledToChat function chatID is $chatID');
    List<Map<String, dynamic>> usersFromDB = [];

    var usersInvolved;
    await for (var user in chatsUsers!) {
      if (user.data != null) {
        usersInvolved = user.data();
        usersInvoledInChat = usersInvolved;
        removeAlreadyChattingUsersFromUsersList();
      }
    }

    if (usersInvolved != null) {
      setState(() {
        usersInvoledInChat = usersInvolved!['usersInvolvedUID'];
      });
    }

    return usersFromDB;
  }

  removeAlreadyChattingUsersFromUsersList() {
    var tempUsers = users;
    List<String> usersToRemoveUID = [];
    for (var element in tempUsers) {
      var userUID = element['userUID'];
      if (usersInvoledInChat['usersInvolvedUID'][userUID] != null) {
        usersToRemoveUID.add(userUID);
      }
    }

    for (var userToRemoveUID in usersToRemoveUID) {
      tempUsers.removeWhere((element) => element['userUID'] == userToRemoveUID);
    }
    //Check because got error of unmounted object
    if (mounted) {
      setState(() {
        users = tempUsers;
      });
    } else {
      users = tempUsers;
    }
  }

  @override
  void initState() {
    super.initState();
    chatsUsers = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.arguments['chatID'])
        .snapshots();
    getAllUsers();
    getUsersInvoledInChat(widget.arguments['chatID']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dodaj użytkownika'),
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
          'Dodaj użytkownika:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return UserThumbnail(
                  userName: users[index]['username'],
                  userUID: users[index]['userUID'],
                  chatID: widget.arguments['chatID'],
                );
              }),
        ),
      ]),
    );
  }
}
