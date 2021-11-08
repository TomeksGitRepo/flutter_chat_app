// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:giffy_dialog/giffy_dialog.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../common_widgets/simple_button.dart';
// import '../datasources/firebase_datasource.dart';

// class FirebaseTestPage extends StatefulWidget {
//   final String firebaseAppToken;
//   final String packageName = 'com.example.chat_app';
//   final String sharedLastKeyReference = 'FcmServerKey';

//   FirebaseTestPage(this.firebaseAppToken);

//   final FirebaseDataSource firebaseDataSource = FirebaseDataSource();

//   @override
//   _FirebaseTestPageState createState() => _FirebaseTestPageState();
// }

// class _FirebaseTestPageState extends State<FirebaseTestPage> {
//   final _formKey = GlobalKey<FormState>();
//   TextEditingController _serverKeyTextController;

//   bool notificationsAllowed = false;

//   @override
//   void initState() {
//     super.initState();

//     AwesomeNotifications().createdStream.listen((receivedNotification) {
//       String createdSourceText =
//           AssertUtils.toSimpleEnumString(receivedNotification.createdSource);
//       Fluttertoast.showToast(msg: '$createdSourceText notification created');
//     });

//     AwesomeNotifications().displayedStream.listen((receivedNotification) {
//       String createdSourceText =
//           AssertUtils.toSimpleEnumString(receivedNotification.createdSource);
//       Fluttertoast.showToast(msg: '$createdSourceText notification displayed');
//     });

//     AwesomeNotifications().dismissedStream.listen((receivedNotification) {
//       String dismissedSourceText = AssertUtils.toSimpleEnumString(
//           receivedNotification.dismissedLifeCycle);
//       Fluttertoast.showToast(
//           msg: 'Notification dismissed on $dismissedSourceText');
//     });

//     AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
//       setState(() {
//         notificationsAllowed = isAllowed;
//       });

//       if (!isAllowed) {
//         requestUserPermission(isAllowed);
//       }
//     });
//   }

//   void requestUserPermission(bool isAllowed) async {
//     showDialog(
//         context: context,
//         builder: (_) => NetworkGiffyDialog(
//               buttonOkText:
//                   Text('Allow', style: TextStyle(color: Colors.white)),
//               buttonCancelText:
//                   Text('Later', style: TextStyle(color: Colors.white)),
//               buttonCancelColor: Colors.grey,
//               buttonOkColor: Colors.deepPurple,
//               buttonRadius: 0.0,
//               image: Image.network(
//                   "https://thumbs.gfycat.com/BlindZigzagGreatargus-small.gif",
//                   fit: BoxFit.cover),
//               title: Text('Get Notified!',
//                   textAlign: TextAlign.center,
//                   style:
//                       TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600)),
//               description: Text(
//                 'Allow Awesome Notifications to send you beautiful notifications!',
//                 textAlign: TextAlign.center,
//               ),
//               entryAnimation: EntryAnimation.DEFAULT,
//               onCancelButtonPressed: () async {
//                 Navigator.of(context).pop();
//                 notificationsAllowed =
//                     await AwesomeNotifications().isNotificationAllowed();
//                 setState(() {
//                   notificationsAllowed = notificationsAllowed;
//                 });
//               },
//               onOkButtonPressed: () async {
//                 Navigator.of(context).pop();
//                 await AwesomeNotifications()
//                     .requestPermissionToSendNotifications();
//                 notificationsAllowed =
//                     await AwesomeNotifications().isNotificationAllowed();
//                 setState(() {
//                   notificationsAllowed = notificationsAllowed;
//                 });
//               },
//             ));
//   }

//   void processDefaultActionReceived(ReceivedAction receivedNotification) {
//     Fluttertoast.showToast(msg: 'Action received');

//     String targetPage;

//     // Avoid to open the notification details page over another details page already opened
//     Navigator.pushNamedAndRemoveUntil(context, targetPage,
//         (route) => (route.settings.name != targetPage) || route.isFirst,
//         arguments: receivedNotification);
//   }

//   void processInputTextReceived(ReceivedAction receivedNotification) {
//     Fluttertoast.showToast(
//         msg: 'Msg: ' + receivedNotification.buttonKeyInput,
//         backgroundColor: Colors.blue,
//         textColor: Colors.white);
//   }

//   @override
//   void dispose() {
//     AwesomeNotifications().createdSink.close();
//     AwesomeNotifications().displayedSink.close();
//     AwesomeNotifications().actionSink.close();
//     super.dispose();
//   }

//   String serverKeyValidation(value) {
//     if (value.isEmpty) {
//       return 'The FCM server key is required';
//     }

//     if (!RegExp(r'^[A-z0-9\:\-\_]{150,}$').hasMatch(value)) {
//       return 'Enter Valid FCM server key';
//     }

//     return null;
//   }

//   Future<String> getLastServerKey() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString(widget.sharedLastKeyReference) ?? '';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           centerTitle: true,
//           title: Text('Firebase Push Test', style: TextStyle(fontSize: 20)),
//           elevation: 10,
//         ),
//         body: FutureBuilder<String>(
//           future: getLastServerKey(),
//           builder: (context, AsyncSnapshot<String> snapshot) {
//             if (!snapshot.hasData) {
//               return Center(
//                   child: CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
//               ));
//             } else {
//               String lastServerKey = snapshot.data;
//               _serverKeyTextController =
//                   TextEditingController(text: lastServerKey);
//               return ListView(
//                   padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
//                   children: <Widget>[
//                     Text('Firebase App Token:'),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 15.0),
//                       child: Text(widget.firebaseAppToken,
//                           style: TextStyle(color: Colors.blue)),
//                     ),
//                     SimpleButton(
//                       'Copy Firebase app token',
//                       onPressed: () async {
//                         if (widget.firebaseAppToken.isNotEmpty) {
//                           Clipboard.setData(
//                               ClipboardData(text: widget.firebaseAppToken));
//                           Fluttertoast.showToast(msg: 'Token copied');
//                         }
//                       },
//                     ),
//                     SizedBox(height: 30),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20.0),
//                       child: Form(
//                         key: _formKey,
//                         autovalidate: false,
//                         child: Column(
//                           children: <Widget>[
//                             TextFormField(
//                               minLines:
//                                   1, //Normal textInputField will be displayed
//                               maxLines:
//                                   5, // when user presses enter it will adapt to it
//                               keyboardType: TextInputType.multiline,
//                               controller: _serverKeyTextController,
//                               validator: serverKeyValidation,
//                               decoration: InputDecoration(
//                                   border: OutlineInputBorder(),
//                                   prefixIcon: Icon(Icons.lock),
//                                   labelText: ' Firebase Server Key ',
//                                   hintText:
//                                       'Paste here your Firebase server Key'),
//                             )
//                           ],
//                         ),
//                       ),
//                     ),
//                     Text(
//                       MapUtils.printPrettyMap(
//                         widget.firebaseDataSource.getFirebaseExampleContent(
//                             firebaseAppToken:
//                                 _serverKeyTextController.value.text),
//                       ),
//                     ),
//                     SimpleButton(
//                       'Send Firebase request',
//                       onPressed: () async {
//                         String fcmServerKey =
//                             _serverKeyTextController.value.text;
//                         SharedPreferences prefs =
//                             await SharedPreferences.getInstance();
//                         prefs.setString(
//                             widget.sharedLastKeyReference, fcmServerKey);

//                         if (_formKey.currentState.validate()) {
//                           FocusScopeNode currentFocus = FocusScope.of(context);
//                           if (!currentFocus.hasPrimaryFocus) {
//                             currentFocus.unfocus();
//                           }

//                           var result =
//                               await pushFirebaseNotification(1, fcmServerKey);
//                           print(
//                               'result from pushFirebaseNotification: $result');
//                         }
//                       },
//                     ),
//                     SimpleButton('Show simple notification',
//                         onPressed: () => showBasicNotification(2)),
//                   ]);
//             }
//           },
//         ));
//   }

//   Future<String> pushFirebaseNotification(
//       int id, String firebaseServerKey) async {
//     //just for testing
//     //final user = FirebaseAuth.instance.currentUser;
//     //var userIdToken = await user.getIdToken();

//     sleep(Duration(seconds: 5));
//     return await widget.firebaseDataSource.pushBasicNotification(
//       firebaseServerKey: firebaseServerKey,
//       firebaseAppToken: widget.firebaseAppToken,
//       notificationId: id,
//       title: 'Notification through firebase',
//       body:
//           'This notification was sent through firebase messaging cloud services.',
//       payload: {'uuid': 'testPayloadKey'},
//     );
//   }

//   Future<void> showBasicNotification(int id) async {
//     await AwesomeNotifications().createNotification(
//       content: NotificationContent(
//         id: id,
//         channelKey: 'basic_channel',
//         title: 'Simple Notification',
//         body: 'Simple body',
//       ),
//     );
//   }
// }
