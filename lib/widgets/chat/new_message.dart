import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xxxx/logic/bloc/networkConnectionBloc/networkmanager_bloc.dart';
import 'package:xxxx/utils/messeging_fcm.dart';
import 'package:uuid/uuid.dart';

enum CustomImageSourceStatus {
  NotPicking,
  Picking,
}

class NewMessage extends StatefulWidget {
  var chatID;
  List<String>? usersUIDToSendMessageTo;

  NewMessage({this.chatID, this.usersUIDToSendMessageTo});

  @override
  _NewMessageState createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  File? _pickedImage;
  bool isMessageProcessing = false;

  final _controller = new TextEditingController();
  var _enteredMessage = '';
  CustomImageSourceStatus currentPickingImageStatus =
      CustomImageSourceStatus.NotPicking;

  void _sendMessage() async {
    setState(() {
      isMessageProcessing = true;
    });
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;
    // var userIdToken = await user.getIdToken();
    // print(' user token in _sendMessage $userIdToken');
    String randomName = Uuid().v4();

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    String? url;

    if (_pickedImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_custom_image')
          .child(randomName +
              '.jpg'); //TODO check if all images can be save as .jpg

      await ref.putFile(_pickedImage!);
      url = await ref.getDownloadURL();
    }
    if (url != null) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatID)
          .collection('messages')
          .add({
        'text': _enteredMessage,
        'createdAt': Timestamp.now(),
        'userUID': user.uid,
        'userName': userData['username'],
        'attachedImageURL': url,
      });
      setState(() {
        _pickedImage = null;
      });
    } else {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatID)
          .collection('messages')
          .add({
        'text': _enteredMessage,
        'createdAt': Timestamp.now(),
        'userUID': user.uid,
        'userName': userData['username'],
      });
    }

    _controller.clear();
    var chatData = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatID)
        .get();
    Map<String, dynamic> usersInvolvedInChat = chatData['usersInvolvedUID'];
    Map<String, dynamic> allUsersInvolvedTokens = chatData['usersInvolvedUID'];
    usersInvolvedInChat.remove(user.uid);
    if (widget.usersUIDToSendMessageTo != null &&
        widget.usersUIDToSendMessageTo!.length > 0) {
      List<String> listUsersUIDToRemove = [];
      for (var element in usersInvolvedInChat.entries) {
        var indexOfUIDInList =
            widget.usersUIDToSendMessageTo!.indexWhere((e) => e == element.key);
        if (indexOfUIDInList == -1) {
          listUsersUIDToRemove.add(element.key);
        }
      }
      listUsersUIDToRemove.forEach((element) {
        usersInvolvedInChat.remove(element);
      });
    } else if (widget.usersUIDToSendMessageTo != null ||
        widget.usersUIDToSendMessageTo!.length == 0) {
      usersInvolvedInChat = {};
    }

    setState(() {
      isMessageProcessing = false;
    });
    if (usersInvolvedInChat.isNotEmpty) {
      await sendAndRetrieveMessage(
          title: userData['username'],
          body: _enteredMessage,
          chatID: widget.chatID,
          usersToNotify: usersInvolvedInChat,
          allUsersInvoledTokens: allUsersInvolvedTokens);
    }
  }

  //TODO change picked image to webp format
  void _pickImage({@required bool? fromCamera}) async {
    final picker = ImagePicker();
    ImageSource source;
    if (fromCamera!) {
      source = ImageSource.camera;
    } else {
      source = ImageSource.gallery;
    }

    final pickedImage = await picker.getImage(
      source: source,
      imageQuality: 60,
    );

    final pickedImageFile = File(pickedImage?.path as String);
    setState(() {
      _pickedImage = pickedImageFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          if (currentPickingImageStatus == CustomImageSourceStatus.Picking)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  child: InkWell(
                    enableFeedback: true,
                    child: Row(
                      children: [
                        Text('Wybierz zdjecie z galerii  '),
                        Icon(Icons.insert_photo)
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        currentPickingImageStatus =
                            CustomImageSourceStatus.NotPicking;
                      });
                      _pickImage(fromCamera: false);
                    },
                  ),
                ),
                Container(
                  child: InkWell(
                    enableFeedback: true,
                    child: Row(
                      children: [
                        Text('Zrób zdjęcie  '),
                        Icon(Icons.photo_camera)
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        currentPickingImageStatus =
                            CustomImageSourceStatus.NotPicking;
                      });
                      _pickImage(fromCamera: true);
                    },
                  ),
                )
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: true,
                  enableSuggestions: true,
                  controller: _controller,
                  decoration: InputDecoration(labelText: 'Wyślij wiadomość...'),
                  onChanged: (value) {
                    setState(() {
                      _enteredMessage = value;
                    });
                  },
                ),
              ),
              if (currentPickingImageStatus != CustomImageSourceStatus.Picking)
                IconButton(
                  icon: Icon(Icons.photo_camera),
                  onPressed: () {
                    setState(() {
                      currentPickingImageStatus =
                          CustomImageSourceStatus.Picking;
                    });
                  },
                ),
              if (!isMessageProcessing)
                BlocBuilder<NetworkmanagerBloc, NetworkmanagerState>(
                    builder: (context, state) {
                  if (state is NetworkConnectionOffline) {
                    return Column(
                      children: [
                        Icon(Icons.mobile_off),
                        Text('Brak Internetu')
                      ],
                    );
                  }
                  return IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _enteredMessage.trim().isNotEmpty ||
                            _pickedImage != null
                        ? _sendMessage
                        : null,
                  );
                }),
              if (isMessageProcessing) CircularProgressIndicator(),
            ],
          ),
          if (_pickedImage != null)
            Column(
              children: [
                InkWell(
                  child: Text(
                    'Usuń zdjęcie',
                    style: TextStyle(fontSize: 20),
                  ),
                  onTap: () {
                    setState(() {
                      _pickedImage = null;
                    });
                  },
                ),
                Image.file(_pickedImage!),
              ],
            )
        ],
      ),
    );
  }
}
