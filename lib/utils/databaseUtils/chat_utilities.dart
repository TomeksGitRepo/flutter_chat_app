import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> checkIfUserBanned(
  String sendingUserUID,
  String receivingUserUID,
) async {
  var result = await FirebaseFirestore.instance
      .collection("users")
      .doc(receivingUserUID)
      .get();

  List<dynamic>? listOfBannedUsers = result.data()!['bannedUsersUID'];
  if (listOfBannedUsers == null) {
    return false;
  }

  var indexOfSendingUser = listOfBannedUsers.indexOf(sendingUserUID);

  return indexOfSendingUser != -1 ? true : false;
}
