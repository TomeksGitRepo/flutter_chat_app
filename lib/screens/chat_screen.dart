import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/networkConnectionBloc/networkmanager_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/logic/bloc/users/users_repository_bloc.dart';
import 'package:xxxx/routes.dart';
import 'package:xxxx/utils/databaseUtils/chat_utilities.dart';
import 'package:xxxx/widgets/chat/messages.dart';
import 'package:xxxx/widgets/chat/new_message.dart';
import 'package:flutter/material.dart';
import 'package:xxxx/widgets/internet/NoInternectConnectionMessage.dart';

class ChatScreen extends StatefulWidget {
  final arguments;

  ChatScreen({this.arguments});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Map<String, dynamic>? involvedUsers;
  bool isUserBanned = false;
  List<String> _bannedByUsersUID = [];
  List<String> _bannedByAdminUsersUID = [];
  List<String> _chatAdminUID = [];
  List<String> _involvedUsersList = [];
  bool isReciverBanned = false;
  DocumentSnapshot? chatSnapshot;
  bool _isUserAdmin = false;
  List<String> _usersToSendNotificationsTo = [];
  Map<String, List<String>> _usersInThisChatBannedMap = {};

  @override
  void initState() {
    super.initState();
    involvedUsers = widget.arguments['usersInvolvedUID'];
    var involvedUsersList = involvedUsers!.keys.toList();
    _involvedUsersList = involvedUsersList;
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.arguments['chatID'])
        .get()
        .then((result) async {
      chatSnapshot = result;
      _chatAdminUID = chatSnapshot!.data()!['adminsUID'].cast<String>();
      _isUserAdmin = checkIfUserIsAdmin();
      getBannedAndAdminsUIDs();
      generateUsersUIDToSendPushNotificationByThisUser();
    });
    if (!widget.arguments['isGroupChat']) {
      var otherUser = involvedUsersList.firstWhere(
          (element) => element != FirebaseAuth.instance.currentUser!.uid);
      checkIfUserBanned(
        FirebaseAuth.instance.currentUser!.uid,
        otherUser,
      ).then((result) {
        if (result) {
          _bannedByUsersUID.add(otherUser);
        }
        setState(() {
          isUserBanned = result;
        });
      });

      checkIfUserBanned(
        otherUser,
        FirebaseAuth.instance.currentUser!.uid,
      ).then((result) {
        setState(() {
          isReciverBanned = result;
        });
      });
    }
  }

  void getBannedAndAdminsUIDs() async {
    if (widget.arguments['isGroupChat']) {
      getBannedByAdminsUID().then((result) async {
        _bannedByAdminUsersUID = result!;
      }).then((_) {
        if (checkIfUserBannedByAdmin()) {
          setState(() {
            isUserBanned = true;
          });
        }
      });
    }
  }

  @override
  dispose() {
    super.dispose();
  }

  Future<List<String>?> getBannedByAdminsUID() async {
    var usersBannedByAdminUIDData =
        await chatSnapshot!.data()!['usersBannedByAdminUID'];
    List<dynamic>? bannedByAdminsUsersUID = usersBannedByAdminUIDData;
    if (bannedByAdminsUsersUID != null) {
      return bannedByAdminsUsersUID.cast<String>();
    }
    return null;
  }

  bool checkIfUserIsAdmin() {
    if (_chatAdminUID.indexOf(FirebaseAuth.instance.currentUser!.uid) != -1) {
      return true;
    } else {
      return false;
    }
  }

  Future<Null> generateUsersUIDToSendPushNotificationByThisUser() async {
    _usersInThisChatBannedMap =
        Map.fromIterable(_involvedUsersList, key: (e) => e, value: (e) => []);

    await removeUsersWhosBlockedSendingUser();
    await generateListOfUIDToSendMessageTo();
    print('After map creation!');
    return null;
  }

  Future<void> removeUsersWhosBlockedSendingUser() async {
    for (var item in _usersInThisChatBannedMap.entries) {
      var result = await getUsersBannedListFromServer(item.key);
      if (result != null) {
        _usersInThisChatBannedMap[item.key] = result;
        print("Map affter addition");
      }
    }
  }

  Future<List<String>?> getUsersBannedListFromServer(String userUID) async {
    var result =
        await FirebaseFirestore.instance.collection('users').doc(userUID).get();

    if (result.data()?['bannedUsersUID'] == null) {
      return null;
    }
    return List<String>.from(result.data()?['bannedUsersUID']);
  }

  generateListOfUIDToSendMessageTo() {
    String userUID = FirebaseAuth.instance.currentUser!.uid;
    _usersInThisChatBannedMap.remove(userUID);
    var keysToRemove = [];
    for (var entry in _usersInThisChatBannedMap.entries) {
      if (entry.value.contains(userUID)) {
        keysToRemove.add(entry.key);
      }
    }
    keysToRemove.forEach((element) {
      _usersInThisChatBannedMap.remove(element);
    });

    setState(() {
      _usersToSendNotificationsTo = _usersInThisChatBannedMap.keys.toList();
    });

    print('After generating _usersToSendNotificationsTo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isUserBanned != true
            ? Text(widget.arguments['chatName'])
            : Text('${widget.arguments['chatName']} zablokował Cię'),
        actions: [
          if (widget.arguments['isGroupChat'] == true)
            IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => Navigator.pushNamed(
                    context, ADDING_USER_TO_CHAT_SCREEN,
                    arguments: {'chatID': widget.arguments['chatID']})),
          PopupMenuButton(
              itemBuilder: (context) {
                List<PopupMenuEntry<Object>> unbannedPopupItems = [];
                List<PopupMenuEntry<Object>> bannedPopupItems = [];
                List<PopupMenuEntry<Object>> adminPopupItems = [];

                if (!widget.arguments['isGroupChat']) {
                  generateUnbaanedPopupItems(unbannedPopupItems);
                  generateBannedPopupItems(bannedPopupItems);
                }

                if (widget.arguments['isGroupChat'] && _isUserAdmin) {
                  generateGroupAdminPopupItems(adminPopupItems);
                  return adminPopupItems;
                }

                if (!isReciverBanned && !widget.arguments['isGroupChat']) {
                  return unbannedPopupItems;
                } else if (isReciverBanned &&
                    !widget.arguments['isGroupChat']) {
                  return bannedPopupItems;
                }

                List<PopupMenuEntry<Object>> onlyLogoutButton = [];
                onlyLogoutButton.add(
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.black,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Wyloguj'),
                      ],
                    ),
                  ),
                );

                return onlyLogoutButton;
              },
              icon: Icon(Icons.more_vert,
                  color: Theme.of(context).primaryIconTheme.color),
              onSelected: (itemIdentifier) async {
                if (itemIdentifier == 0) {
                  print('Adding user to banned');
                  var otherUserUID = involvedUsers!.keys.firstWhere((element) =>
                      element != FirebaseAuth.instance.currentUser!.uid);

                  setState(() {
                    isReciverBanned = true;
                  });

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({
                    'bannedUsersUID': [otherUserUID]
                  });
                }
                if (itemIdentifier == 1) {
                  BlocProvider.of<UserBloc>(context).add(LogoutUser(context));
                  Navigator.pushNamed(context, AUTH_SCREEN);
                }
                if (itemIdentifier == 2) {
                  setState(() {
                    isReciverBanned = false;
                  });
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({'bannedUsersUID': FieldValue.delete()});
                }
                if (itemIdentifier == 3) {
                  Navigator.pushNamed(context, GROUP_CHAT_ADMIN_PANEL_SCREEN,
                      arguments: {
                        'usersInvolvedUID':
                            widget.arguments['usersInvolvedUID'],
                        'chatID': widget.arguments['chatID'],
                        'bannedUsersUID': _bannedByAdminUsersUID
                      });
                }
              }),
        ],
      ),
      body: widget.arguments['isGroupChat'] == true && isUserBanned
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.report,
                    color: Colors.red,
                    size: 150.0,
                  ),
                  SizedBox(height: 45),
                  Text(
                    "Administrator chatu zablokował Cię na czacie. Skontaktuj się z administrtorem czatu w celu usunięcia blokady.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                      'Przeglądanie czatu oraz wysyłanie wiadomości wyłączone.')
                ],
              ),
            )
          : Container(
              color: isUserBanned == true
                  ? Colors.red
                  : Color.fromRGBO(255, 205, 105, 1),
              child: Stack(
                children: [
                  BlocProvider(
                    create: (context) => UsersRepositoryBloc(),
                    child: Column(
                      children: [
                        Messages(chatID: widget.arguments['chatID']),
                        NewMessage(
                            chatID: widget.arguments['chatID'],
                            usersUIDToSendMessageTo:
                                _usersToSendNotificationsTo),
                      ],
                    ),
                  ),
                  BlocBuilder<NetworkmanagerBloc, NetworkmanagerState>(
                      builder: (context, state) {
                    if (state is NetworkConnectionOffline) {
                      return NoInternetConnectionMessage();
                    }
                    return Container();
                  }),
                ],
              ),
            ),
    );
  }

  void generateGroupAdminPopupItems(
      List<PopupMenuEntry<Object>> adminPopupItems) {
    adminPopupItems.add(
      PopupMenuItem(
        value: 3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings,
              color: Colors.black,
            ),
            SizedBox(
              width: 8,
            ),
            Text('Panel administratora'),
          ],
        ),
      ),
    );

    adminPopupItems.add(
      PopupMenuItem(
        value: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              color: Colors.black,
            ),
            SizedBox(
              width: 8,
            ),
            Text('Wyloguj'),
          ],
        ),
      ),
    );
  }

  void generateBannedPopupItems(List<PopupMenuEntry<Object>> bannedPopupItems) {
    bannedPopupItems.add(
      PopupMenuItem(
        value: 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_chat_read,
              color: Colors.black,
            ),
            SizedBox(
              width: 8,
            ),
            Text('Odblokuj użytkownika'),
          ],
        ),
      ),
    );

    bannedPopupItems.add(
      PopupMenuItem(
        value: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              color: Colors.black,
            ),
            SizedBox(
              width: 8,
            ),
            Text('Wyloguj'),
          ],
        ),
      ),
    );
  }

  void generateUnbaanedPopupItems(
      List<PopupMenuEntry<Object>> unbannedPopupItems) {
    unbannedPopupItems.add(
      PopupMenuItem(
        value: 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_disabled,
              color: Colors.black,
            ),
            SizedBox(
              width: 8,
            ),
            Text('Zablokuj użytkownika'),
          ],
        ),
      ),
    );

    unbannedPopupItems.add(
      PopupMenuItem(
        value: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              color: Colors.black,
            ),
            SizedBox(
              width: 8,
            ),
            Text('Wyloguj'),
          ],
        ),
      ),
    );
  }

  bool checkIfUserBannedByAdmin() {
    var userUID = FirebaseAuth.instance.currentUser!.uid;
    if (_bannedByAdminUsersUID.indexOf(userUID) != -1) {
      return true;
    } else {
      return false;
    }
  }
}
