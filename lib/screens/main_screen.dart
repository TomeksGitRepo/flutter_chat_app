import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/networkConnectionBloc/networkmanager_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/logic/managers/LatestNewsClickManager.dart';
import 'package:xxxx/logic/managers/NetworkConnectionManager.dart';
import 'package:xxxx/logic/managers/LatestChatManager.dart';
import 'package:xxxx/routes.dart';
import 'package:xxxx/utils/autoUpdate/currentAppInfo.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xxxx/utils/common_functions.dart';
import 'package:xxxx/widgets/internet/NoInternectConnectionMessage.dart';

enum PostPriority { normal, high }

class Post {
  String title;
  PostPriority priority;
  Post(this.title, this.priority);
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  CurrentAppInfo? currentAppInfo;
  var userBloc;
  var resultFromUser = FirebaseAuth.instance.currentUser;
  List<Post> _postToProcess = [];
  int importantPostsNumber = 0;
  DateTime? lastOpenNews;
  DateTime? now;
  DateTime? lastWeekDate;
  bool userPlatformUpdated = false;
  LatestChatManager latestChatManager = new LatestChatManager();
  String? latestChat;
  LatestNewsClickManager? _latestNewsClickManager;
  String isOpenedFromNotification = 'Still loading';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (AppLifecycleState.resumed == state) {
      latestChatManager.getlatestChatIDFromDB().then((value) {
        setState(() {
          latestChat = value;
        });
      });
      checkIfNeedsRedirectingToChat(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    FirebaseMessaging.instance.getInitialMessage().then((value) {
      if (value != null) {
        setState(() {
          isOpenedFromNotification = "Yep opened from notification";
        });
      } else {
        setState(() {
          isOpenedFromNotification =
              "NOPE not from notification opened from notification";
        });
      }
    });

    now = DateTime.now();
    lastWeekDate = now!.subtract(new Duration(days: 7));

    updateUserPlatform();
    latestChatManager.init().then((_) {
      latestChatManager.getlatestChatIDFromDB().then((value) {
        setState(() {
          latestChat = value;
        });
      });
    });

    _latestNewsClickManager = new LatestNewsClickManager();
    _latestNewsClickManager!.init();
    _latestNewsClickManager!.getlatestNewsClickFromDB().then((result) {
      if (result == 'No lastNewsClick data') {
        getLastWeeksPostsFromWebsite();
        return;
      }
      setState(() {
        lastOpenNews = DateTime.parse(result);
        print('setState after lastOpenNews');
      });
      getLastWeeksPostsFromWebsite();
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      checkIfNeedsRedirectingToChat(context);
    });

    currentAppInfo ??= CurrentAppInfo(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Ekran główny'),
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
                      Icon(Icons.settings),
                      SizedBox(
                        width: 8,
                      ),
                      Text('Ustawienia'),
                    ],
                  ),
                ),
                value: 'settings',
              ),
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
              } else if (itemIdentifier == 'settings') {
                Navigator.pushNamed(context, APPLICATION_SETTINGS_SCREEN);
              }
            },
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            BlocBuilder<NetworkmanagerBloc, NetworkmanagerState>(
                builder: (context, state) {
              if (state is NetworkConnectionOffline) {
                return NoInternetConnectionMessage();
              }
              return Container();
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      child: ConstrainedBox(
                          constraints: BoxConstraints.tight(Size(150, 150)),
                          child: FlatButton(
                            onPressed: () async {
                              var currentTime = DateTime.now();
                              _latestNewsClickManager!.insertLatestNewsClick(
                                  currentTime.toString());
                              await _latestNewsClickManager!
                                  .getlatestNewsClickFromDB();
                              setState(() {
                                lastOpenNews = currentTime;
                              });

                              Navigator.pushNamed(
                                  context, PAGE_WEBSITE_WEBVIEW);
                            },
                            child: Badge(
                              badgeContent: Text(
                                getNumberOfUnreadedPosts().toString(),
                                style: TextStyle(fontSize: 24),
                              ),
                              badgeColor: importantPostsNumber > 0
                                  ? Colors.red
                                  : Colors.yellow,
                              showBadge:
                                  _postToProcess.length > 0 ? true : false,
                              child: Image.asset(
                                'assets/main_screen/icons/papirus.jpg',
                                fit: BoxFit.fill,
                              ),
                            ),
                          )),
                    ),
                    Text('Aktualności'),
                  ],
                ),
                BlocBuilder<UserBloc, UserblocState>(
                  builder: (context, state) {
                    if (state is UserData) {
                      if (state.userData.isAPPMember == true) {
                        return Column(
                          children: [
                            Container(
                              child: ConstrainedBox(
                                constraints: BoxConstraints.expand(
                                    width: 150, height: 150),
                                child: FlatButton(
                                  onPressed: () => {
                                    Navigator.pushNamed(
                                        context, PAGE_CHATS_MAIN_SCREEN),
                                  },
                                  child: Image(
                                    image: AssetImage(
                                      'assets/main_screen/icons/chat.png',
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Text('Chat')
                          ],
                        );
                        // debugPrint("User IS member");
                      } else {
                        return Column(
                          children: [
                            Container(
                              child: ConstrainedBox(
                                constraints: BoxConstraints.expand(
                                    width: 150, height: 150),
                                child: FlatButton(
                                  onPressed: () => {
                                    Navigator.pushNamed(
                                        context, PAGE_CHATS_MAIN_SCREEN)
                                  },
                                  child: Image(
                                    image: AssetImage(
                                      'assets/main_screen/icons/no_chat.png',
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Text('Chat wyłacznie dla Firm Upoważnionych')
                          ],
                        );
                      }
                    }
                    return Container();
                  },
                )
              ],
              mainAxisSize: MainAxisSize.max,
            ),
            FlatButton(
              onPressed: () async {
                latestChatManager.insertLatestChatID('Dummy string');

                print('dummy tekst inserted in database');
              },
              child: Text('Set dummy chat id'),
            ),
            FlatButton(
              onPressed: () async {
                latestChat = await latestChatManager.getlatestChatIDFromDB();
                print('latestChat is $latestChat');
              },
              child: Text('Print latest chatinfo'),
            ),
            FlatButton(
              onPressed: () {
                currentAppInfo!.printVersion();
              },
              child: Text('Display app info'),
            ),
            FlatButton(
              onPressed: () {
                print(
                  'Current app version is: ${currentAppInfo!.currentVersion}',
                );
                print(
                  'Current app version link is: ${currentAppInfo!.linkToLatesVersion}',
                );
                currentAppInfo!.checkIfUpdateAvible();
              },
              child: Text('Display web info'),
            ),
            FlatButton(
              onPressed: () {
                BlocProvider.of<UserBloc>(context).add(CheckUserTokenAndOS());
              },
              child: Text("Check for user token and os correctness in DB."),
            ),
            FlatButton(
              onPressed: () {
                _latestNewsClickManager!.clearDBTable();
              },
              child: Text("Reset database lastNewsClick data."),
            ),
            Text(
                isOpenedFromNotification), //TODO this is just form debugging and isOpenedFromNotification is same
            FlatButton(
              onPressed: () {
                BlocProvider.of<NetworkmanagerBloc>(context)
                    .add(ApplicationOfflineEvent());
              },
              child: Text("Send application offline event"),
            ),
            FlatButton(
              onPressed: () {
                BlocProvider.of<NetworkmanagerBloc>(context)
                    .add(ApplicationOnlineEvent());
              },
              child: Text("Send application online event"),
            ),
            NetworkConnectionManager(),
          ],
        ),
      ),
    );
  }

  checkIfNeedsRedirectingToChat(context) {
    if (latestChat != null && latestChat != 'No lastChat data') {
      Navigator.pushNamed(context, PAGE_CHAT_MAIN_SCREEN,
          arguments: latestChat);
      latestChat = null;
    }
  }

  updateUserPlatform() {
    if (userPlatformUpdated) {
      return;
    }
    var useremail = FirebaseAuth.instance.currentUser!.email;
    FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: useremail)
        .get()
        .then((doc) async {
      var result = doc.docs.first.data();
      result!["userPlatform"] = getPlatform();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.docs.first.id)
          .set(result);

      userPlatformUpdated = true;
    });
  }

  getNumberOfUnreadedPosts() {
    if (importantPostsNumber > 0) {
      return importantPostsNumber;
    } else {
      return _postToProcess.length;
    }
  }

  getLastWeeksPostsFromWebsite() async {
    final DateFormat formatter = DateFormat('dd');
    String dayWith2Numbers = formatter.format(lastWeekDate!);
    DateFormat monthFormatter = DateFormat('MM');
    String monthWith2Number = monthFormatter.format(lastWeekDate!);

    var urlToSend;
    if (lastOpenNews == null || lastWeekDate!.isAfter(lastOpenNews!)) {
      urlToSend =
          'http://xxxx.pl/wp-json/wp/v2/posts?categories=94&per_page=30&after=${lastWeekDate!.year}-$monthWith2Number-${dayWith2Numbers}T00:00:00'; // client's wordpress news url
    } else {
      dayWith2Numbers = formatter.format(lastOpenNews!);
      monthWith2Number = monthFormatter.format(lastOpenNews!);
      DateFormat hourMinutsSecondsFormater = DateFormat('HH:mm:ss');
      String hoursMinutsSeconds =
          hourMinutsSecondsFormater.format(lastOpenNews!);
      urlToSend =
          'http://xxxx.pl/wp-json/wp/v2/posts?categories=94&per_page=30&after=${lastOpenNews!.year}-$monthWith2Number-${dayWith2Numbers}T$hoursMinutsSeconds';
    }

    var posts = await http.get(Uri.parse(urlToSend));
    var resultBody = posts.body;
    var parsedResult = jsonDecode(resultBody);
    for (var entry in parsedResult) {
      String entryTitle = entry['title']['rendered'] as String;
      if (entryTitle.toLowerCase().contains('ważne:')) {
        setState(() {
          _postToProcess
              .add(Post(entry['title']['rendered'], PostPriority.high));
          importantPostsNumber = importantPostsNumber + 1;
        });
      } else {
        setState(() {
          _postToProcess
              .add(Post(entry['title']['rendered'], PostPriority.normal));
        });
      }
    }
    print(parsedResult);
  }
}
