import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xxxx/logic/managers/LatestChatManager.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

class UsersChatManager {
  Future<bool> checkIfCanCreateIndyvidualChat(
      Map<String, Map<String, String>> usersInvolvedUID) async {
    QuerySnapshot indyvidualChats = await FirebaseFirestore.instance
        .collection('chats')
        .where('isGroupChat', isEqualTo: false)
        .get();

    var elements = indyvidualChats.docs.map((element) {
      return element;
    });
    var isChatAlreadyExisting = elements.any((element) {
      var usersInvolvedUIDFromDB =
          element.data()?['usersInvolvedUID'] as Map<String, dynamic>;
      var usersInvolvedUIDFromDBKeys = usersInvolvedUIDFromDB.keys.toList();
      var usersInvolvedUIDKey = usersInvolvedUID.keys.toList();
      var areEquals = true;

      for (var i = 0; i < usersInvolvedUIDFromDBKeys.length; i++) {
        for (var j = 0; j < usersInvolvedUIDKey.length; j++) {
          if (usersInvolvedUIDFromDBKeys[i] == usersInvolvedUIDKey[j]) {
            break;
          }
          if (usersInvolvedUIDFromDBKeys[i] != usersInvolvedUIDKey[j] &&
              j == usersInvolvedUIDKey.length - 1) {
            areEquals = false;
          }
        }
      }

      return areEquals;
    });
    return isChatAlreadyExisting;
  }
}
