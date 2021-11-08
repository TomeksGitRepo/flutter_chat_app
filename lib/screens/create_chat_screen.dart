import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xxxx/utils/messeging_fcm.dart';
import 'package:xxxx/widgets/chat/create_chat_form.dart';
import '../utils/common_functions.dart';

class CreateChatScreen extends StatefulWidget {
  @override
  _CreateChatScreen createState() => _CreateChatScreen();
}

class _CreateChatScreen extends State<CreateChatScreen> {
  var isLoading = false;
  void _submitAuthForm(
    String chatName,
    bool isGroupChat,
    String userUID,
    BuildContext ctx,
  ) async {
    var adminsUID = [];
    adminsUID.add(userUID);
    var userFirebaseToken = await getFirebaseMessagingToken();

    var usersInvolvedUID = new Map();
    usersInvolvedUID[userUID] = {
      'token': userFirebaseToken,
      "userPlatform": getPlatform()
    };

    await FirebaseFirestore.instance.collection('chats').add({
      'adminsUID': adminsUID,
      'chatID': 'removeThis',
      'chatName': chatName,
      'isGroupChat': isGroupChat,
      'usersInvolvedUID': usersInvolvedUID,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: CreateChatForm(_submitAuthForm, isLoading),
    );
  }
}
