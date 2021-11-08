import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/users/users_repository_bloc.dart';
import 'package:xxxx/routes.dart';
import 'package:string_validator/string_validator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:sizer/sizer.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final String username;
  final Timestamp creationDate;
  final String? userAvatarUrl;
  final String? creatorUID;
  final String? attachedImageURL;
  final Key? key;
  var _isValidURL = false;
  MessageBubble(
    this.message,
    this.isMe,
    this.username,
    this.creationDate, {
    this.key,
    this.userAvatarUrl,
    this.creatorUID,
    this.attachedImageURL,
  }) {
    if (isURL(message.toLowerCase())) {
      _isValidURL = true;
    }
  }

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  double _fontSize = 20;
  final double _baseFontSize = 20;
  double _fontScale = 1;
  double _baseFontScale = 1;
  String? _userAvatarURL;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isValidURL) {
      return generateWebViewForURL(widget.message);
    }
    if (widget.isMe) {
      return generateUserOwnMessages();
    } else {
      return RepaintBoundary(
        child: Row(
          children: [
            Column(children: [
              _userAvatarURL != null
                  ? Container(
                      width: 50,
                      height: 50,
                      //TODO make this image circle its square now
                      child: Image(
                        image: CachedNetworkImageProvider(
                          _userAvatarURL!,
                          maxWidth: 50,
                          maxHeight: 50,
                        ),
                      ),
                    )
                  : Container(
                      child: Text('Brak zdjęcia'),
                      width: 50,
                      height: 50,
                    ),
              Text.rich(TextSpan(
                style: TextStyle(
                  fontSize: _fontSize * 0.75,
                  fontWeight: FontWeight.bold,
                ),
                text: widget.username + '\n',
              )),
            ]),
            generateOtherUsersMessages(context)
          ],
        ),
      );
    }
  }

  Widget generateUserOwnMessages() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomLeft: Radius.circular(15),
        ),
      ),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(children: [
          if (widget.attachedImageURL != null)
            InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                SHOW_IMAGE_FULL_SCREEN,
                arguments: widget.attachedImageURL!,
              ),
              child: CachedNetworkImage(
                  height: 100, imageUrl: widget.attachedImageURL!),
              // child: Image(
              //   height: 100,
              //   frameBuilder: (BuildContext context, Widget child, int? frame,
              //       bool? wasSynchronouslyLoaded) {
              //     if (wasSynchronouslyLoaded ?? false) {
              //       print('Imagage loaded syncronously');
              //       return child;
              //     }
              //     return AnimatedOpacity(
              //       child: child,
              //       opacity: frame == null ? 0 : 1,
              //       duration: const Duration(seconds: 1),
              //       curve: Curves.easeOut,
              //     );
              //   },
              //   image: CachedNetworkImageProvider(
              //     widget.attachedImageURL!,
              //   ),
              // ),
            ),
          Container(
            width: 90.0.w,
            child: Text.rich(
              buildTextSpan(),
            ),
          )
        ]),
      ),
    );
  }

  Widget generateOtherUsersMessages(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(20),
      child: widget._isValidURL
          ? generateWebViewForURL(widget.message)
          : Column(
              children: [
                Row(
                  children: [
                    BlocListener<UsersRepositoryBloc, UsersRepositoryBlocState>(
                      listener: (context, state) {
                        if (_userAvatarURL != null) {
                          return;
                        }
                        if (state is UserInfoReturnedFromCache) {
                          if (state.userFound.userUID == widget.creatorUID) {
                            setState(() {
                              _userAvatarURL = state.userFound.userAvatarURL;
                            });
                          } else {
                            print('In else in BlocListener');
                            setState(() {
                              _userAvatarURL = null;
                            });
                          }
                        }
                      },
                      child: Container(),
                    ),
                    if (widget.attachedImageURL != null)
                      InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          SHOW_IMAGE_FULL_SCREEN,
                          arguments: widget.attachedImageURL!,
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 100,
                              child: CachedNetworkImage(
                                  memCacheHeight: 100,
                                  height: 100,
                                  imageUrl: widget.attachedImageURL!),
                              // child: Image(
                              //   height: 100,
                              //   frameBuilder: (BuildContext context,
                              //       Widget child,
                              //       int? frame,
                              //       bool? wasSynchronouslyLoaded) {
                              //     if (wasSynchronouslyLoaded ?? false) {
                              //       print('Imagage loaded syncronously');
                              //       return child;
                              //     }
                              //     return AnimatedOpacity(
                              //       child: child,
                              //       opacity: frame == null ? 0 : 1,
                              //       duration: const Duration(milliseconds: 300),
                              //       curve: Curves.easeOut,
                              //     );
                              //   },
                              //   image: CachedNetworkImageProvider(
                              //     widget.attachedImageURL!,
                              //   ),
                              // ),
                            ),
                            Text.rich(buildOtherUserTextSpan())
                          ],
                        ),
                      ),
                    if (widget.attachedImageURL == null)
                      Text.rich(buildOtherUserTextSpan())
                  ],
                ),
              ],
            ),
    );
  }

  TextSpan buildTextSpan() {
    return TextSpan(style: TextStyle(fontSize: _fontSize), children: [
      TextSpan(
        text: widget.message,
      ),
      TextSpan(
        style: TextStyle(
          fontSize: _fontSize * 0.55,
          fontWeight: FontWeight.w300,
        ),
        text: '   ${addMessageTime()}',
      )
    ]);
  }

  TextSpan buildOtherUserTextSpan() {
    return TextSpan(
        style: TextStyle(
          fontSize: _fontSize,
        ),
        children: [
          TextSpan(text: widget.message),
          TextSpan(
            style: TextStyle(
              fontSize: _fontSize * 0.55,
              fontWeight: FontWeight.w300,
            ),
            text: '\n   ${addMessageTime()}',
          )
        ]);
  }

  String addMessageTime() {
    Timestamp messageCreationTime = widget.creationDate;
    String hourAndMinuteOfMessageCreation =
        DateFormat('HH:mm').format(messageCreationTime.toDate());
    return hourAndMinuteOfMessageCreation;
  }

  Widget generateWebViewForURL(String url) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomLeft: Radius.circular(15),
        ),
      ),
      margin: EdgeInsets.all(15),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          TextButton(
              onPressed: () async {
                var urlLowerCase = url.toLowerCase().trim();
                if (await canLaunch(urlLowerCase)) {
                  await launch(urlLowerCase);
                } else {
                  throw 'Could not launch $urlLowerCase';
                }
              },
              child: Text("Otwórz w przeglądarce")),
          Text.rich(
            TextSpan(children: [
              WidgetSpan(
                child: ClipRect(
                  child: Expanded(
                    child: WebView(
                      javascriptMode: JavascriptMode.unrestricted,
                      debuggingEnabled: false,
                      gestureNavigationEnabled: true,
                      initialUrl: widget.message,
                    ),
                  ),
                ),
              )
            ]),
          ),
        ],
      ),
    );
  }
}
