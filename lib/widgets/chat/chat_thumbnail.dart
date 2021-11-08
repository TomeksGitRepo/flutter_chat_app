import 'package:flutter/material.dart';
import 'package:xxxx/routes.dart';
import 'package:intl/intl.dart';

class ChatThumbnail extends StatelessWidget {
  final String? chatName;
  final String? chatID;
  final dynamic? lastMessage;
  final bool? isGroupChat;
  final Map<String, dynamic>? usersInvolvedUID;

  ChatThumbnail(
      {this.chatName,
      @required this.chatID,
      this.lastMessage,
      this.isGroupChat,
      this.usersInvolvedUID});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: EdgeInsets.only(top: 3, bottom: 5),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          PAGE_CHAT_MAIN_SCREEN,
          arguments: {
            'chatName': chatName,
            'chatID': chatID,
            'isGroupChat': isGroupChat,
            'usersInvolvedUID': usersInvolvedUID,
          },
        ),
        child: Row(children: [
          Column(
            children: [],
          ),
          Expanded(
            child: Column(
              children: [
                Text(" $chatName",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    )),
                Text(
                  lastMessage != null
                      ? lastMessage['text']
                      : 'Brak wiadomości. Zacznij konwersację.',
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (lastMessage != null)
                Text(DateFormat('HH:mm')
                    .format(lastMessage['createdAt'].toDate())),
              if (lastMessage != null)
                Text(DateFormat('dd/MM')
                    .format(lastMessage['createdAt'].toDate()))
            ],
          ),
        ]),
      ),
    );
  }
}
