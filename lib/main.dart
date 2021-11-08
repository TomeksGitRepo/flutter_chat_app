import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:xxxx/dataModels/Message.dart';
import 'package:xxxx/dataModels/Timestamp.dart';
import 'package:xxxx/dataModels/User.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/logic/managers/LatestChatManager.dart';
import 'package:xxxx/routes.dart';
import 'package:xxxx/screens/auth_screen.dart';
import 'package:xxxx/screens/main_screen.dart';
import 'package:xxxx/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging_platform_interface/src/method_channel/method_channel_messaging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'dataModels/Chat.dart' as ChatData;
import 'dataModels/Timestamp.dart' as myTimestamp;
import 'dataModels/MyTimestampAdapter.dart';
import 'logic/bloc/networkConnectionBloc/networkmanager_bloc.dart';
import 'logic/managers/LatestNewsClickManager.dart';

void main() async {
  // debugProfilePaintsEnabled = true;
  // debugProfileBuildsEnabled = true;
  // debugProfileLayoutsEnabled = true;
  // debugRepaintRainbowEnabled = true;

  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp();

  Directory? storageDirectory = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: storageDirectory,
  );
  Hive.init(storageDirectory.path);
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(ChatData.ChatAdapter());
  Hive.registerAdapter(TimestampAdapter());
  Hive.registerAdapter(MessageAdapter());
  cf.FirebaseFirestore.instance.clearPersistence();
  Hive.openBox<ChatData.Chat>('userChatsInfo');
  // FirebaseFirestore.instance.settings = Settings(cacheSizeBytes: 5000000);
  //FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);
  runApp(MyApp());
}

Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  LatestChatManager latestChatManager = new LatestChatManager();
  latestChatManager.init();
  String messageContentString = message.data['content'];

  var parsedMessageData = jsonDecode(messageContentString);
  print(
      'parsedMessageData in myBackgroundMessageHandler chatID is ${parsedMessageData['chatID']}');
  latestChatManager.insertLatestChatID(parsedMessageData['chatID']);

  print("onBackgroundMessage message.data.entries: ${message.data.entries}");
  //_showBigPictureNotification(message);
  return Future<RemoteMessage>.value(message);
}

void processOnMessageEvent(RemoteMessage message) async {
  LatestChatManager latestChatManager = new LatestChatManager();
  await latestChatManager.init();
  String messageContentString = message.data['content'];

  var parsedMessageData = jsonDecode(messageContentString);
  print(
      'parsedMessageData in processOnMessageEvent chatID is ${parsedMessageData['chatID']}');
  await latestChatManager.insertLatestChatID(parsedMessageData['chatID']);
}

//TODO finish this
void processoOnMessageOpenedApp(RemoteMessage message) {
  SnackBar(content: Text('processoOnMessageOpenedApp called'));
  print('processing message in onMessageOpenedApp $message');
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MethodChannelFirebaseMessaging? messaging;
  LatestNewsClickManager? _latestNewsClickManager;
  bool _initialized = false;
  bool _error = false;
  FirebaseApp? _firebaseApp;

  // Define an async function to initialize FlutterFire
  Future<FirebaseApp?> initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      setState(() {
        _initialized = true;
      });
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
      FirebaseMessaging.onMessage.listen(processOnMessageEvent);
      FirebaseMessaging.onMessageOpenedApp.listen(processoOnMessageOpenedApp);
      if (Platform.isIOS) {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
      }
      WidgetsFlutterBinding.ensureInitialized();
      return Firebase.initializeApp();
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire().then((result) {
      WidgetsFlutterBinding.ensureInitialized();
      //messaging = new MethodChannelFirebaseMessaging(app: _firebaseApp);
      setState(() {
        _firebaseApp = result;
      });
    });

    // if (Platform.isAndroid) {
    //   messaging = new MethodChannelFirebaseMessaging();
    // }

    _latestNewsClickManager = new LatestNewsClickManager();
    _latestNewsClickManager!.init();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return CircularProgressIndicator();
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(),
        ),
        BlocProvider<NetworkmanagerBloc>(create: (context) {
          return NetworkmanagerBloc();
        })
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OrientationBuilder(
            builder: (context, orientation) {
              SizerUtil().init(constraints, orientation);
              return MaterialApp(
                checkerboardRasterCacheImages: false,
                routes: materialRoutes,
                title: 'xxxx',
                theme: ThemeData(
                  pageTransitionsTheme: PageTransitionsTheme(builders: {
                    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  }),
                  primarySwatch: Colors.blue,
                  backgroundColor: Colors.pink,
                  accentColor: Colors.deepPurple,
                  accentColorBrightness: Brightness.dark,
                  buttonTheme: ButtonTheme.of(context).copyWith(
                      buttonColor: Colors.pink,
                      textTheme: ButtonTextTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20))),
                ),
                home: _firebaseApp != null
                    ? BlocBuilder<UserBloc, UserblocState>(
                        builder: (context, state) {
                          if (state is UserblocInitial) {
                            return SplashScreen();
                          } else if (state is UserData) {
                            return MainScreen();
                          } else if (state is UserLoggedOut) {
                            return AuthScreen();
                          }
                          return AuthScreen();
                        },
                      )
                    : CircularProgressIndicator(),
              );
            },
          );
        },
      ),
    );
  }
}
