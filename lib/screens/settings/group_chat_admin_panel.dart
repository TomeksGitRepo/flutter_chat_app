import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter/material.dart';
import 'package:xxxx/dataModels/User.dart' as myUser;
import 'package:xxxx/logic/managers/UserInfoManager.dart';

class GroupChatScreen extends StatefulWidget {
  Map<String, dynamic>? _arguments;
  GroupChatScreen({Object? arguments}) {
    _arguments = arguments as Map<String, dynamic>?;
  }

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  List<String>? _usersInvolvedUID;
  UserInfoManager? _userInfoManager;
  String? _chatID;
  List<String>? _bannedUsersUID;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _usersInvolvedUID = widget._arguments!['usersInvolvedUID'].keys.toList();
    _chatID = widget._arguments!['chatID'];
    _userInfoManager = UserInfoManager();
    _bannedUsersUID = widget._arguments!['bannedUsersUID'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Panel administratora'),
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            height: 8,
          ),
          Text('Zablokuj/odblokuj użytkownika:'),
          Expanded(
            child: ListView.builder(
                itemCount: _usersInvolvedUID!.length,
                itemBuilder: (context, index) {
                  return FutureBuilder(
                    future: _userInfoManager!
                        .getUserInfoByUID(_usersInvolvedUID![index]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        var thisUserUID =
                            (snapshot.data as myUser.User).userUID;
                        //TODO remove this in production. Commented just for easier development
                        // if (thisUserUID ==
                        //     fa.FirebaseAuth.instance.currentUser!.uid) {
                        //   return Container();
                        // }
                        String userName =
                            (snapshot.data as myUser.User).username!;
                        bool isUserBanned = false;
                        bool isLoading = false;
                        if (_bannedUsersUID != null) {
                          var indexInBannedList =
                              _bannedUsersUID!.indexOf(thisUserUID!);
                          if (indexInBannedList != -1) {
                            isUserBanned = true;
                          }
                        }

                        return UserCard(
                          isUserBanned: isUserBanned,
                          chatID: _chatID,
                          thisUserUID: thisUserUID,
                          username: userName,
                        );
                      }

                      return Card(
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading:
                                Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Wczytywanie...'),
                          ),
                          TextButton(
                            child: const Text('ZABLOKUJ'),
                            onPressed: () {/* ... */},
                          ),
                        ],
                      ));
                    },
                  );
                }),
          ),
          TextButton(
              onPressed: () {
                _userInfoManager!.clearBox();
              },
              child: Text('Reset cache for userInfoManager')),
        ])

        // Column(
        //   children: [
        //     SizedBox(
        //       height: 8,
        //     ),
        //     Text('Zablokuj/odblokuj użytkownika:'),
        //     Card(
        //       child: Column(
        //         mainAxisSize: MainAxisSize.min,
        //         children: <Widget>[
        //           const ListTile(
        //             leading: Icon(Icons.check_circle, color: Colors.green),
        //             title: Text('The Enchanted Nightingale'),
        //           ),
        //           TextButton(
        //             child: const Text('ZABLOKUJ'),
        //             onPressed: () {/* ... */},
        //           ),
        //         ],
        //       ),
        //     ),
        //     Card(
        //       child: Column(
        //         mainAxisSize: MainAxisSize.min,
        //         children: <Widget>[
        //           const ListTile(
        //             leading: Icon(Icons.report, color: Colors.red),
        //             title: Text('The Enchanted Nightingale'),
        //           ),
        //           TextButton(
        //             child: const Text('ODBLOKUJ'),
        //             onPressed: () {/* ... */},
        //           ),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
        );
  }
}

class UserCard extends StatefulWidget {
  const UserCard({
    Key? key,
    required this.isUserBanned,
    required String? chatID,
    required this.thisUserUID,
    required this.username,
  })   : _chatID = chatID,
        super(key: key);

  final bool isUserBanned;
  final String? _chatID;
  final String? thisUserUID;
  final String username;

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool isLoading = false;
  bool isUserBanned = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isUserBanned = widget.isUserBanned;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: isUserBanned
              ? Icon(Icons.report, color: Colors.red)
              : Icon(Icons.check_circle, color: Colors.green),
          title: Text(widget.username),
        ),
        if (!isLoading)
          TextButton(
            child:
                isUserBanned ? const Text('ODBLOKUJ') : const Text('ZABLOKUJ'),
            onPressed: isUserBanned
                ? () async {
                    isLoading = true;
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget._chatID)
                        .update({
                      'usersBannedByAdminUID':
                          FieldValue.arrayRemove([widget.thisUserUID])
                    }).then((_) {
                      setState(() {
                        isLoading = false;
                        isUserBanned = !isUserBanned;
                      });
                    });
                  }
                : () async {
                    isLoading = true;
                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget._chatID)
                        .update(
                      {
                        'usersBannedByAdminUID':
                            FieldValue.arrayUnion([widget.thisUserUID])
                      },
                    ).then((_) {
                      setState(() {
                        isLoading = false;
                        isUserBanned = !isUserBanned;
                      });
                    });
                  },
          ),
        if (isLoading) CircularProgressIndicator()
      ],
    ));
  }
}
