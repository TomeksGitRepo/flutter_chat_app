import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:xxxx/logic/managers/UsersChatManagers.dart';
import 'package:xxxx/utils/common_functions.dart';

import '../../routes.dart';

class UserThumbnail extends StatefulWidget {
  final String? userName;
  final String? userUID;
  final String? chatID;

  UserThumbnail({this.userName, this.userUID, this.chatID});

  @override
  _UserThumbnailState createState() => _UserThumbnailState();
}

class _UserThumbnailState extends State<UserThumbnail> {
  FirebaseAuth? mAuth;
  User? firebaseUser;
  String? error;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    mAuth = FirebaseAuth.instance;
    firebaseUser = mAuth!.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userUID == firebaseUser!.uid) return Container();
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(top: 5, bottom: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue,
              ),
            ),
            child: InkWell(
              onTap: () async {
                setState(() {
                  isChecking = true;
                });
                var userToken = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userUID)
                    .get();
                if (widget.chatID != null) {
                  //if chatID pressent its addition user to existing chat
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatID)
                      .update({
                    'usersInvolvedUID.${widget.userUID}': {
                      'token': userToken['userFirebaseAuthToken'],
                      'userPlatform': userToken['userPlatform'],
                    },
                  });
                } else {
                  var creatingUserUID = firebaseUser!.uid;

                  var choosenUserToken = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userUID)
                      .get();

                  var creatingUserToken = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(creatingUserUID)
                      .get();

                  var creatingUserName = creatingUserToken['username'];

                  var usersInvolvedList = Map<String, Map<String, String>>();

                  var chatAdmins = [];
                  chatAdmins.add(widget.userUID);
                  chatAdmins.add(creatingUserUID);

                  var newChatInfo = Map<String, dynamic>();
                  newChatInfo["adminsUID"] = chatAdmins;
                  newChatInfo["chatName"] =
                      "${widget.userName}-//-$creatingUserName";
                  newChatInfo["isGroupChat"] = false;
                  newChatInfo["usersInvolvedUID"] = usersInvolvedList;
                  //Creating users data
                  usersInvolvedList[creatingUserUID] =
                      new Map<String, String>();
                  usersInvolvedList[creatingUserUID] = {
                    'token': creatingUserToken['userFirebaseAuthToken'],
                    'userPlatform': getPlatform(),
                  };
                  //Choosen user data

                  usersInvolvedList[widget.userUID!] = {
                    'token': choosenUserToken['userFirebaseAuthToken'],
                    'userPlatform': choosenUserToken['userPlatform']
                  };

                  UsersChatManager usersChatManager = UsersChatManager();
                  bool isChatExisting = await usersChatManager
                      .checkIfCanCreateIndyvidualChat(usersInvolvedList);
                  if (!isChatExisting) {
                    if (mounted) {
                      setState(() {
                        isChecking = false;
                      });
                    }

                    await FirebaseFirestore.instance
                        .collection('chats')
                        .add(newChatInfo);
                    Navigator.pushNamed(context, PAGE_CHATS_MAIN_SCREEN);
                  } else {
                    setState(() {
                      isChecking = false;
                      error =
                          'Chat indywidualny z użytkownikiem ${widget.userName!} już istnieje lub użytkownik Cię zablokował.';
                    });
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isChecking) CircularProgressIndicator(),
                        if (!isChecking)
                          Text(
                            error != null ? error! : widget.userName!,
                            style: TextStyle(
                              height: error == null ? 2.5 : 1.5,
                              fontSize: error == null ? 20 : 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
