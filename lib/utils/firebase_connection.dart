// import 'package:flutter/material.dart';
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:flutter/services.dart';
// import 'package:xxxx/utils/messeging_fcm.dart';

// class FirebaseConnections extends StatefulWidget {
//   @override
//   _FirebaseConnectionsState createState() => _FirebaseConnectionsState();
// }

// class _FirebaseConnectionsState extends State<FirebaseConnections> {
//   String _firebaseAppToken = 'xxxx';
//   String packageName = 'com.example.chat_app';
//   String firebaseMessagingToken;

//   @override
//   void initState() {
//     super.initState();
//     initializeFirebaseService();
//     getFirebaseMessagingToken().then((value) => firebaseMessagingToken = value);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         child: Column(
//       children: [
//         // Text("firebaseMessagingToken: $firebaseMessagingToken"),
//         // FlatButton(
//         //     onPressed: () => Navigator.pushNamed(context, PAGE_FIREBASE_TESTS,
//         //         arguments: _firebaseAppToken),
//         //     child: Text('Go to test page'))
//       ],
//     ));
//   }

//   Future<void> initializeFirebaseService() async {
//     String firebaseAppToken;
//     bool isFirebaseAvailable;

//     // Platform messages may fail, so we use a try/catch PlatformException.
//     try {
//       isFirebaseAvailable = await AwesomeNotifications().isFirebaseAvailable;

//       if (isFirebaseAvailable) {
//         try {
//           // final user = await FirebaseAuth.instance.currentUser();
//           // var userIdToken = await user.getIdToken();
//           //TODO changing from appToken to userToken
//           firebaseAppToken = await AwesomeNotifications().firebaseAppToken;
//           debugPrint('Firebase token: $firebaseAppToken');

//           // firebaseAppToken = userIdToken.token;
//         } on PlatformException {
//           firebaseAppToken = null;
//           debugPrint('Firebase failed to get token');
//         }
//       } else {
//         firebaseAppToken = null;
//         debugPrint('Firebase is not available on this project');
//       }
//     } on PlatformException {
//       isFirebaseAvailable = false;
//       firebaseAppToken = 'Firebase is not available on this project';
//     }

//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) {
//       _firebaseAppToken = firebaseAppToken;
//       return;
//     }

//     setState(() {
//       _firebaseAppToken = firebaseAppToken;
//     });
//   }
// }
