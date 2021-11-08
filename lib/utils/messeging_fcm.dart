import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:xxxx/utils/common_functions.dart';

final String serverToken =
    'xxxx';
final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

Future<String?> getFirebaseMessagingToken() async {
  return firebaseMessaging.getToken();
}

sendAndRetrieveMessage({
  String? title,
  String? body,
  String? chatID,
  Map<String, dynamic>? usersToNotify,
  Map<String, dynamic>? allUsersInvoledTokens,
}) async {
  var randomGenerator = new Random();
  Map<String, dynamic>? allUsersTokens = allUsersInvoledTokens;
  List<String> androidUsers = [];
  List<String> iosUsers = [];

  allUsersTokens!.forEach((key, value) {
    if (value['userPlatform'] == 'android') {
      androidUsers.add(value['token']);
    } else if (value['userPlatform'] == 'ios') {
      iosUsers.add(value['token']);
    }
  });

  await firebaseMessaging.requestPermission();

  var userToken = await firebaseMessaging.getToken();
  var userOSSystem = getPlatform();

  List<String> androidUsersToNotify;
  List<String> iosUsersToNotify;

  if (userOSSystem == 'android') {
    androidUsersToNotify = new List.from(androidUsers);
    androidUsersToNotify.remove(userToken);
  } else {
    androidUsersToNotify = new List.from(androidUsers);
  }

  if (userOSSystem == 'ios') {
    iosUsersToNotify = new List.from(iosUsers);
    iosUsersToNotify.remove(userToken);
  } else {
    iosUsersToNotify = new List.from(iosUsers);
  }

  sendToAndroidFCM(androidUsersToNotify, randomGenerator, title!, body!,
          chatID!, allUsersTokens, androidUsers, iosUsers)
      .then((value) => print('sendToAndroidFCM function finished'));

  sendToIOSFCM(iosUsersToNotify, randomGenerator, title, body, chatID,
          allUsersTokens, androidUsers, iosUsers)
      .then((value) => print('sendToIOSFCM function finished'));
}

Future sendToAndroidFCM(
    List<String> androidUsersToNotify,
    Random randomGenerator,
    String title,
    String body,
    String chatID,
    Map<String, dynamic> allUsersTokens,
    List<String> androidUsers,
    List<String> iosUsers) async {
  if (androidUsersToNotify != null && androidUsersToNotify.length > 0) {
    var messageID = randomGenerator.nextInt(100000);
    try {
      String url = 'https://fcm.googleapis.com/fcm/send';
      Response response;
      Dio dio = new Dio();
      response = await dio.post(url,
          data: json.encode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              "content": {
                "id": messageID,
                "body": body,
                "channelKey": "basic_channel",
                "title": title,
                "notificationLayout": "BigPicture",
                "largeIcon":
                    "https://xxxx.pl",
                "bigPicture": "https://xxxx.pl",
                "showWhen": true,
                "autoCancel": true,
                "privacy": "Private",
                "chatID": chatID,
                "allUsersInvoledTokens": allUsersTokens,
                "androidUsersInvolvedTokens": androidUsers,
                "iosUsersInvolvedTokens": iosUsers,
              }
            },
            'registration_ids': androidUsersToNotify,
          }),
          options: Options(headers: {
            Headers.contentTypeHeader: 'application/json',
            'Authorization': 'key=$serverToken',
          }));
      print(response);

      // //TODO change post request there are some problemst with handshade
      // HttpClient client = new HttpClient();
      // client.badCertificateCallback =
      //     ((X509Certificate cert, String host, int port) {
      //   print('In badCertificateCallback');
      //   return true;
      // });
      // String url = 'https://fcm.googleapis.com/fcm/send';
      // HttpClientRequest request = await client.postUrl(Uri.parse(url));
      // request.headers.set('Content-Type', 'application/json');
      // request.headers.set('Authorization', 'key=$serverToken');
      // request.add(utf8.encode(json.encode(<String, dynamic>{
      //   'priority': 'high',
      //   'data': <String, dynamic>{
      //     "content": {
      //       "id": messageID,
      //       "channelKey": "basic_channel",
      //       "title": title,
      //       "body": body,
      //       "notificationLayout": "BigPicture",
      //       "largeIcon":
      //           "https://avidabloga.files.wordpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg",
      //       "bigPicture": "https://www.dw.com/image/49519617_303.jpg",
      //       "showWhen": true,
      //       "autoCancel": true,
      //       "privacy": "Private",
      //       "chatID": chatID,
      //       "allUsersInvoledTokens": allUsersTokens,
      //       "androidUsersInvolvedTokens": androidUsers,
      //       "iosUsersInvolvedTokens": iosUsers,
      //     }
      //   },
      //   'registration_ids': androidUsersToNotify,
      // })));
      // HttpClientResponse response = await request.close();
      // String reply = await response.transform(utf8.decoder).join();
      // print('reply from new request is $reply');
      // client.close();

      // var result = await http.post(
      //   'https://fcm.googleapis.com/fcm/send',
      //   headers: <String, String>{
      //     'Content-Type': 'application/json',
      //     'Authorization': 'key=$serverToken',
      //   },
      //   body: jsonEncode(
      //     <String, dynamic>{
      //       'priority': 'high',
      //       'data': <String, dynamic>{
      //         "content": {
      //           "id": messageID,
      //           "channelKey": "basic_channel",
      //           "title": title,
      //           "body": body,
      //           "notificationLayout": "BigPicture",
      //           "largeIcon":
      //               "https://avidabloga.files.wordpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg",
      //           "bigPicture": "https://www.dw.com/image/49519617_303.jpg",
      //           "showWhen": true,
      //           "autoCancel": true,
      //           "privacy": "Private",
      //           "chatID": chatID,
      //           "allUsersInvoledTokens": allUsersTokens,
      //           "androidUsersInvolvedTokens": androidUsers,
      //           "iosUsersInvolvedTokens": iosUsers,
      //         }
      //       },
      //       'registration_ids': androidUsersToNotify,
      //     },
      //   ),
      // );
      // print('Result from sending message.${result.body}');
    } catch (e) {
      print('Error sending message to FCM $e');
    }
  }
}

Future sendToIOSFCM(
    List<String> iosUsersToNotify,
    Random randomGenerator,
    String title,
    String body,
    String chatID,
    Map<String, dynamic> allUsersTokens,
    List<String> androidUsers,
    List<String> iosUsers) async {
  if (iosUsersToNotify != null && iosUsersToNotify.length > 0) {
    var messageID = randomGenerator.nextInt(100000);
    String url = 'https://fcm.googleapis.com/fcm/send';

    Response response;
    Dio dio = new Dio();
    response = await dio.post(url,
        data: json.encode(<String, dynamic>{
          'priority': 'high',
          "click_action": "MESSAGE_ACTION",
          "notification": {
            "title": title,
            "body": body,
            'sound': 'default',
            "click_action": "MESSAGE_ACTION",
          },
          'data': <String, dynamic>{
            "content": {
              "id": messageID,
              "channelKey": "basic_channel",
              "title": title,
              "body": body,
              "notificationLayout": "BigPicture",
              "largeIcon":
                  "https://xxxx.jpg",
              "bigPicture": "https://xxxx.jpg",
              "showWhen": true,
              "autoCancel": true,
              "privacy": "Private",
              "chatID": chatID,
              "allUsersInvoledTokens": allUsersTokens,
              "androidUsersInvolvedTokens": androidUsers,
              "iosUsersInvolvedTokens": iosUsers,
            }
          },
          'registration_ids': iosUsersToNotify,
        }),
        options: Options(headers: {
          Headers.contentTypeHeader: 'application/json',
          'Authorization': 'key=$serverToken',
        }));
    print(response);

    // HttpClient client = new HttpClient();
    // client.badCertificateCallback =
    //     ((X509Certificate cert, String host, int port) {
    //   print('In badCertificateCallback');
    //   return true;
    // });
    // String url = 'https://fcm.googleapis.com/fcm/send';
    // HttpClientRequest request = await client.postUrl(Uri.parse(url));
    // request.headers.set('Content-Type', 'application/json');
    // request.headers.set('Authorization', 'key=$serverToken');
    // request.add(utf8.encode(json.encode(<String, dynamic>{
    //   'priority': 'high',
    //   "click_action": "MESSAGE_ACTION",
    //   "notification": {
    //     "title": title,
    //     "body": body,
    //     'sound': 'default',
    //     "click_action": "MESSAGE_ACTION",
    //   },
    //   'data': <String, dynamic>{
    //     "content": {
    //       "id": messageID,
    //       "channelKey": "basic_channel",
    //       "title": title,
    //       "body": body,
    //       "notificationLayout": "BigPicture",
    //       "largeIcon":
    //           "https://avidabloga.files.wordpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg",
    //       "bigPicture": "https://www.dw.com/image/49519617_303.jpg",
    //       "showWhen": true,
    //       "autoCancel": true,
    //       "privacy": "Private",
    //       "chatID": chatID,
    //       "allUsersInvoledTokens": allUsersTokens,
    //       "androidUsersInvolvedTokens": androidUsers,
    //       "iosUsersInvolvedTokens": iosUsers,
    //     }
    //   },
    //   'registration_ids': iosUsersToNotify,
    // })));
    // HttpClientResponse response = await request.close();
    // String reply = await response.transform(utf8.decoder).join();
    // print('reply from new request is $reply');
    // client.close();

    // try {
    //   var result = await http.post(
    //     'https://fcm.googleapis.com/fcm/send',
    //     headers: <String, String>{
    //       'Content-Type': 'application/json',
    //       'Authorization': 'key=$serverToken',
    //     },
    //     body: jsonEncode(
    //       <String, dynamic>{
    //         'priority': 'high',
    //         "click_action": "MESSAGE_ACTION",
    //         "notification": {
    //           "title": title,
    //           "body": body,
    //           'sound': 'default',
    //           "click_action": "MESSAGE_ACTION",
    //         },
    //         'data': <String, dynamic>{
    //           "content": {
    //             "id": messageID,
    //             "channelKey": "basic_channel",
    //             "title": title,
    //             "body": body,
    //             "notificationLayout": "BigPicture",
    //             "largeIcon":
    //                 "https://avidabloga.files.wordpress.com/2012/08/emmemc3b3riadeneilarmstrong3.jpg",
    //             "bigPicture": "https://www.dw.com/image/49519617_303.jpg",
    //             "showWhen": true,
    //             "autoCancel": true,
    //             "privacy": "Private",
    //             "chatID": chatID,
    //             "allUsersInvoledTokens": allUsersTokens,
    //             "androidUsersInvolvedTokens": androidUsers,
    //             "iosUsersInvolvedTokens": iosUsers,
    //           }
    //         },
    //         'registration_ids': iosUsersToNotify,
    //       },
    //     ),
    //   );
    //   print('Result from sending message.${result.body}');
    // } catch (e) {
    //   print('Error sending message to FCM $e');
    // }
  }
}
