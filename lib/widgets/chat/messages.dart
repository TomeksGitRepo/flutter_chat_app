import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:xxxx/dataModels/Chat.dart';
import 'package:xxxx/dataModels/Message.dart';
import 'package:xxxx/widgets/chat/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:sizer/sizer.dart';

class Messages extends StatefulWidget {
  final String? chatID;

  Messages({this.chatID});

  @override
  _MessagesState createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  var deviceHeight;
  ScrollController scrollController = ScrollController();
  ScrollDirection scrollDirection =
      ScrollDirection.reverse; //Begining ScrollDirection is revers
  String? lastChatMessageDate;
  bool needsDateBubble = true;
  Box<Chat>? userChatsInfo;
  Chat? _thisChatInfo;
  bool _isBuildingFromRemoteDB = false;
  ScrollDirection? _lastScrollDirection;

  @override
  void initState() {
    super.initState();
    userChatsInfo = Hive.box<Chat>('userChatsInfo');
    if (userChatsInfo!.values.isNotEmpty) {
      _thisChatInfo = userChatsInfo!.values
          .firstWhere((element) => element.chatID == widget.chatID);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        width: 100.0.w,
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollController.position.userScrollDirection ==
                    ScrollDirection.reverse) {
                  scrollDirection = ScrollDirection.reverse;
                } else if (scrollController.position.userScrollDirection ==
                    ScrollDirection.forward) {
                  scrollDirection = ScrollDirection.forward;
                }
                return true;
              },
              child: Container(
                width: 100.0.w,
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatID)
                        .collection('messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (ctx, AsyncSnapshot<QuerySnapshot> chatSnapshot) {
                      if (chatSnapshot.connectionState ==
                              ConnectionState.active &&
                          chatSnapshot.data?.docs.length != 0) {
                        return ListView.builder(
                            controller: scrollController,
                            key: Key(Uuid().v4()),
                            shrinkWrap: true,
                            reverse: true,
                            itemCount: chatSnapshot.data?.docs.length,
                            itemBuilder: (ctx, index) {
                              // print('Item creation time');
                              // print(DateTime.now());
                              return Container(
                                width: 80.0.w,
                                child: buildListItem(
                                    messageCreationDate: chatSnapshot
                                        .data!.docs[index]['createdAt'],
                                    currentIndex: index,
                                    listLength: chatSnapshot.data!.docs.length,
                                    listDocs: chatSnapshot.data!.docs,
                                    scrollDirection: scrollDirection),
                              );
                            });
                      }

                      return ListView.builder(
                          controller: scrollController,
                          key: Key(Uuid().v4()),
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: _thisChatInfo!.messages!.length,
                          itemBuilder: (ctx, index) {
                            // print('Item creation time');
                            // print(DateTime.now());
                            return Container(
                              width: 80.0.w,
                              child: buildListItemFromCache(
                                  messageCreationDate:
                                      _thisChatInfo!.messages![index].createdAt,
                                  currentIndex: index,
                                  listLength: _thisChatInfo!.messages!.length,
                                  listDocs: _thisChatInfo!.messages!,
                                  scrollDirection: scrollDirection),
                            );
                          });

                      // return Center(
                      //   child: Text('Wczytywanie'),
                      // );
                    }),
              ),
              //TODO display date in chat screen when user move list
              // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              //   Container(
              //     decoration: BoxDecoration(
              //         color:
              //             Theme.of(context).primaryColor.withAlpha(120),
              //         borderRadius:
              //             BorderRadius.all(Radius.circular(15))),
              //     padding: new EdgeInsets.all(5),
              //     child: Text(
              //       DateFormat('dd-MM-y').format(
              //         chatDocs[lastIndex]['createdAt'].toDate(),
              //       ),
              //     ),
              //   ),
              // ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildListItemFromCache(
      {@required messageCreationDate,
      @required currentIndex,
      @required listLength,
      List<Message>? listDocs,
      @required scrollDirection}) {
    if (listDocs == null) {
      return Container();
    }

    var dateToPrint = lastChatMessageDate.toString();
    var currentDate =
        DateFormat('dd-MM-y').format(messageCreationDate.toDate());
    if (currentDate == lastChatMessageDate) {
      needsDateBubble = false;
      lastChatMessageDate = currentDate;
    }
    if (currentDate != lastChatMessageDate &&
        lastChatMessageDate != null &&
        currentIndex != 0) {
      needsDateBubble = true;
      lastChatMessageDate = currentDate;
    }
    if (lastChatMessageDate == null) {
      needsDateBubble = false;
      lastChatMessageDate = currentDate;
    }
    return Column(
      children: [
        if (currentIndex == listLength - 1) //Display date above first element
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(120),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                padding: new EdgeInsets.all(5),
                child: Text(
                  currentDate,
                ),
              )
            ],
          ),
        if (needsDateBubble &&
            scrollDirection == ScrollDirection.forward &&
            currentIndex != listLength - 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(120),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                padding: new EdgeInsets.all(5),
                child: Text(
                  currentDate,
                ),
              )
            ],
          ),
        Row(
            key: Key(Uuid().v4()),
            mainAxisAlignment: listDocs[currentIndex].userUID ==
                    FirebaseAuth.instance.currentUser!.uid
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: MessageBubble(
                  listDocs[currentIndex].text,
                  listDocs[currentIndex].userUID ==
                      FirebaseAuth.instance.currentUser!.uid,
                  listDocs[currentIndex].userName,
                  listDocs[currentIndex].createdAt,
                  key: Key(Uuid().v4()),
                  creatorUID: listDocs[currentIndex].userUID,
                  attachedImageURL:
                      listDocs[currentIndex].attachedImageURL != null
                          ? listDocs[currentIndex].attachedImageURL
                          : null,
                ),
              ),
            ]),
        if (needsDateBubble && scrollDirection == ScrollDirection.reverse)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(120),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                padding: new EdgeInsets.all(5),
                child: Text(
                  dateToPrint,
                ),
              )
            ],
          ),
      ],
    );
  }

  Widget buildListItem(
      {@required messageCreationDate,
      @required currentIndex,
      @required listLength,
      @required listDocs,
      @required scrollDirection}) {
    if (scrollDirection != _lastScrollDirection) {
      lastChatMessageDate = null;
      _lastScrollDirection = scrollDirection;
    }
    var dateToPrint = lastChatMessageDate.toString();
    var currentDate =
        DateFormat('dd-MM-y').format(messageCreationDate.toDate());
    if (currentDate == lastChatMessageDate) {
      needsDateBubble = false;
      lastChatMessageDate = currentDate;
    }
    if (currentDate != lastChatMessageDate &&
        lastChatMessageDate != null &&
        currentIndex != listLength) {
      needsDateBubble = true;
      lastChatMessageDate = currentDate;
    }
    if (lastChatMessageDate == null) {
      needsDateBubble = false;
      lastChatMessageDate = currentDate;
    }
    return Column(
      children: [
        Text('This message date: $currentDate'),
        if (currentIndex == listLength - 1) //Display date above first element
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(120),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                padding: new EdgeInsets.all(5),
                child: Text(
                  currentDate,
                ),
              )
            ],
          ),
        if (needsDateBubble &&
            scrollDirection == ScrollDirection.forward &&
            currentIndex != listLength - 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(120),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                padding: new EdgeInsets.all(5),
                child: Text(
                  currentDate,
                ),
              )
            ],
          ),
        Row(
            key: Key(Uuid().v4()),
            mainAxisAlignment: listDocs[currentIndex]['userUID'] ==
                    FirebaseAuth.instance.currentUser!.uid
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: MessageBubble(
                  listDocs[currentIndex]['text'],
                  listDocs[currentIndex]['userUID'] ==
                      FirebaseAuth.instance.currentUser!.uid,
                  listDocs[currentIndex]['userName'],
                  listDocs[currentIndex]['createdAt'],
                  key: ValueKey(listDocs[currentIndex].id),
                  creatorUID: listDocs[currentIndex]['userUID'],
                  attachedImageURL: listDocs[currentIndex]
                          .data()!
                          .containsKey('attachedImageURL')
                      ? listDocs[currentIndex]['attachedImageURL']
                      : null,
                ),
              ),
            ]),
        if (needsDateBubble &&
            scrollDirection == ScrollDirection.reverse &&
            currentIndex != 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(120),
                    borderRadius: BorderRadius.all(Radius.circular(15))),
                padding: new EdgeInsets.all(5),
                child: Text(
                  dateToPrint,
                ),
              )
            ],
          ),
      ],
    );
  }
}
