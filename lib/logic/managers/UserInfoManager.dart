import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:xxxx/dataModels/User.dart';

class UserInfoManager {
  Box<User>? userInfoBox;

  UserInfoManager() {
    Hive.openBox<User>('usersCacheInfoBox')
        .then((box) => userInfoBox = box)
        .catchError((error) {
      print('Error opening usersCacheInfoBox $error');

      return Hive.openBox<User>(
          'userInfoBox'); //TODO dunno if opening database on error is the right way to go
    });
  }

  Future<User> getUserInfoByUID(String userUID) async {
    if (userInfoBox == null) {
      userInfoBox = await Hive.openBox<User>('usersCacheInfoBox');
    }
    var resultFromCache = userInfoBox!.get(userUID);

    if (resultFromCache != null) {
      return resultFromCache;
    }

    var resultFromRemoteDB =
        await FirebaseFirestore.instance.collection("users").doc(userUID).get();

    var resultWithUserUID = resultFromRemoteDB.data();
    resultWithUserUID!['userUID'] = resultFromRemoteDB.id;

    User userFromRemote = User.fromMap(resultWithUserUID);

    if (userInfoBox != null) {
      userInfoBox!.put(userUID, userFromRemote);
    }

    return userFromRemote;
  }

  void clearBox() {
    userInfoBox!.clear();
  }
}
