import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:xxxx/dataModels/Message.dart';
import 'package:xxxx/dataModels/Timestamp.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/routes.dart';
import 'package:xxxx/widgets/chat/chat_thumbnail.dart';
import 'package:xxxx/dataModels/User.dart' as MyUser;
import 'package:xxxx/dataModels/Chat.dart';
import 'package:rxdart/rxdart.dart';

const String INDIVIDUAL = 'individual';
const String GROUP = 'group';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  var _choosenChats = INDIVIDUAL;
  String? userName;
  FirebaseAuth? mAuth;
  User? firebaseUser;

  List<Map<String, dynamic>> _usersChats = [];
  List<Map<String, dynamic>> _filteredChats = [];

  List<Map<String, dynamic>> get getInstanceUsersChats {
    return _usersChats;
  }

  Box? userInfoBox;
  MyUser.User? appUserInfo;

  Box? userChatsInfo;
  var initialStreamData;
  var _chatChangeListenerStream;
  bool _isAppGettingUserChats = false;
  List<Stream> streamsList = [];

  @override
  void initState() {
    super.initState();

    mAuth = FirebaseAuth.instance;
    firebaseUser = mAuth!.currentUser;
    //TODO listen for all changes in all chats
    createMessagesStream();
    Future.delayed(Duration.zero,
        () => getUsersChats(FirebaseAuth.instance.currentUser!.uid));
  }

  void createMessagesStream() {
    cf.FirebaseFirestore.instance.collection("chats").get().then(
      (results) async {
        for (var stream in results.docs) {
          streamsList.add(FirebaseFirestore.instance
              .collection('chats')
              .doc(stream.id)
              .collection('messages')
              .snapshots());
        }
        _chatChangeListenerStream = MergeStream(streamsList);
      },
    ).then((result) async {
      _chatChangeListenerStream.listen((event) {
        if ((event as QuerySnapshot).docChanges.length > 0 &&
            event.docChanges.length < 5 &&
            _isAppGettingUserChats == false) {
          getUsersChats(FirebaseAuth.instance.currentUser!.uid);
          print('In listen unser 5 above 0');
        }
        print('Just working');
      });
    });
  }

  //TODO check if local needs update
  getUserInfoFromRemoteDB() async {
    if (userInfoBox!.isEmpty) {
      var userDBData = await cf.FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser!.uid)
          .get();

      Map<String, dynamic> userWithUID = userDBData.data()!;
      userWithUID['userUID'] = firebaseUser!.uid;

      MyUser.User userInfo = MyUser.User.fromJson(userWithUID);
      userInfoBox!.add(userInfo);
      appUserInfo = userInfo;
    } else {
      //TODO update use info from database
      appUserInfo = userInfoBox!.getAt(0);
    }
  }

  applyChatsFillter() async {
    if (userInfoBox == null) {
      userInfoBox = await Hive.openBox('userInfo');
      await getUserInfoFromRemoteDB();
    }

    if (_choosenChats == GROUP) {
      _filteredChats = getInstanceUsersChats
          .where((element) => element['isGroupChat'])
          .toList();
    }
    if (_choosenChats == INDIVIDUAL) {
      _filteredChats = getInstanceUsersChats
          .where((element) => !element['isGroupChat'])
          .toList();
      _filteredChats.forEach((element) {
        if (element['chatName'] == null) {
          return;
        }
        if (userName == null) {
          if (appUserInfo != null) {
            userName = appUserInfo!.username;
          }
        }
        String value = element['chatName'] as String;
        value = value.replaceFirst(userName!, '');
        value = value.replaceFirst('-//-', '');
        element['chatName'] = value;
      });
    }

    _filteredChats.sort((a, b) {
      if (a['lastMessage'] == null) {
        return 1;
      }
      if (b['lastMessage'] == null) {
        return -1;
      }
      //Reversed order last on top
      return b['lastMessage']['createdAt']
          .compareTo(a['lastMessage']['createdAt']);
    });
    if (mounted) {
      setState(() {
        //just to reload UI
      });
    }
  }

  Future<String> getFirestoreUserToken() async {
    var resultFromUser = FirebaseAuth.instance.currentUser;
    var resultIDToken = await resultFromUser!.getIdToken();

    return resultIDToken;
  }

  getUsersChats(String userUID) async {
    // print('started getUsersChats function');
    // print('userUID in getUsersChats is: $userUID');
    //TODO finish from this
    List<Map<String, dynamic>> usersChats = [];
    List<Map<String, dynamic>> _tempUsersChats = [];
    if (_isAppGettingUserChats) {
      return;
    }
    _isAppGettingUserChats = true;
    if (userChatsInfo == null) {
      userChatsInfo = Hive.box<Chat>('userChatsInfo');
    }

    // userChatsInfo!.clear();

    if (userChatsInfo != null) {
      for (var element in userChatsInfo!.keys) {
        Chat result = userChatsInfo!.get(element);
        _tempUsersChats.add(result.toMap());
      }
      if (_tempUsersChats.isNotEmpty && mounted) {
        //if mounted check state
        setState(() {
          _usersChats = _tempUsersChats;
        });
        await applyChatsFillter();
      } else if (_tempUsersChats.isNotEmpty && !mounted) {
        //if not mounted just set variable
        _usersChats = _tempUsersChats;
      }
    }

    var userChatsFromDatabase;
    try {
      userChatsFromDatabase = await cf.FirebaseFirestore.instance
          .collection('chats')
          .where(
            'usersInvolvedUID.$userUID.token',
            isGreaterThan: "", //Little hack to query for not null value in map
          )
          .get();
    } catch (e) {
      _isAppGettingUserChats = false;
      print('error getting chats: $e');
      return;
    }

    if (userChatsFromDatabase.docs.length == 0) {
      return;
    }
    List<Chat> chatsFromDatabase = [];
    for (var entry in userChatsFromDatabase.docs) {
      var elementWithChatID = entry.data();
      elementWithChatID!['chatID'] = entry.id;
      var messagesChat = await cf.FirebaseFirestore.instance
          .collection('chats')
          .doc(entry.id)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .get();
      var lastMessagesChat = await cf.FirebaseFirestore.instance
          .collection('chats')
          .doc(entry.id)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      for (var message in lastMessagesChat.docs) {
        elementWithChatID['lastMessage'] = message.data();
      }
      Chat chatInfo = Chat.fromMap(elementWithChatID);
      for (var message in messagesChat.docs) {
        var messageData = message.data()!;
        Message newMessage = Message.fromMap(messageData);
        chatInfo.messages!.add(newMessage);
      }
      chatsFromDatabase.add(chatInfo);
      usersChats.add(elementWithChatID);
    }
    if (_tempUsersChats.length != usersChats.length && usersChats.length != 0) {
      setState(() {
        _usersChats = usersChats;
      });

      await applyChatsFillter();
      await userChatsInfo!.clear();
      await userChatsInfo!.addAll(chatsFromDatabase);
    }
    //They are the same but messages can be diffrent
    if (_tempUsersChats.length == usersChats.length && mounted) {
      setState(() {
        _usersChats = usersChats;
      });
      await applyChatsFillter();
      await userChatsInfo!.clear();
      await userChatsInfo!.addAll(chatsFromDatabase);
    }
    _isAppGettingUserChats = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chaty'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FlatButton(
              onPressed: () => setState(() {
                _choosenChats = INDIVIDUAL;
                applyChatsFillter();
              }),
              child: Text(
                "Indywidualne",
              ),
              color: _choosenChats == INDIVIDUAL ? Colors.blue : null,
            ),
            FlatButton(
              onPressed: () => setState(() {
                _choosenChats = GROUP;
                applyChatsFillter();
              }),
              child: Text("Grupowe"),
              color: _choosenChats == GROUP ? Colors.blue : null,
            ),
            // TextButton(
            //   child: Text('Clear userInfo box '),
            //   onPressed: () {
            //     userInfoBox?.clear();
            //   },
            // ),
            TextButton(
              child: Text('Clear userChatsInfo'),
              onPressed: () {
                userChatsInfo?.clear();
              },
            ),
          ],
        ),
        // Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        //   //Text('Wybrany chat $_choosenChats'),
        //   FlatButton(
        //     onPressed: () {
        //       print('_usersChart.length is: ${_usersChats.length}');
        //       print('_usersChart values are: ${_usersChats[0]['chatName']}');
        //     },
        //     child: Text("Get data from FB"),
        //   ),
        // ]),
        Expanded(
          child: ListView.builder(
              itemCount: _filteredChats.length,
              itemBuilder: (context, index) {
                return ChatThumbnail(
                  chatName: _filteredChats[index]['chatName'],
                  chatID: _filteredChats[index]['chatID'],
                  lastMessage: _filteredChats[index]['lastMessage'],
                  isGroupChat: _filteredChats[index]['isGroupChat'],
                  usersInvolvedUID: _filteredChats[index]['usersInvolvedUID'],
                );
              }),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, CREATE_CHAT_SCREEN),
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
