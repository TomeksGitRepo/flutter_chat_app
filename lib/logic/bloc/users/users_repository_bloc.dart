import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:xxxx/dataModels/User.dart';
import 'package:meta/meta.dart';

part 'users_repository_bloc_event.dart';
part 'users_repository_bloc_state.dart';

class UsersRepositoryBloc
    extends HydratedBloc<UsersRepositoryBlocEvent, UsersRepositoryBlocState> {
  UsersRepositoryBloc() : super(UsersRepositoryBlocInitial());

  Map<String, User> allSeenUsersInfo = {};

  @override
  Stream<UsersRepositoryBlocState> mapEventToState(
    UsersRepositoryBlocEvent event,
  ) async* {
    if (event is GetUserInfo) {
      if (event.email != null) {
        var itemPositionInList = allSeenUsersInfo[event.email];
        if (itemPositionInList != null) {
          yield UserInfoReturnedFromCache(
              allSeenUsersInfo[itemPositionInList]!);
          return;
        }

        var result = await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: event.email)
            .get();
        if (result.docs.length != 0) {
          var data = result.docs.first.data();
          User userFound = User(
            userUID: result.docs.first.id,
            email: data!['email'],
            isAPPMember: data['isAPPMember'],
            memberCompanyName: data['MemberCompanyName'],
            userFirebaseAuthToken: data['userFirebaseAuthToken'],
            username: data['username'],
            userAvatarURL: data['user_avatar_image_url'],
          );

          allSeenUsersInfo[result.docs.first.id] = userFound;

          yield UserInfoReturnedFromCache(userFound);
          return;
        }
      }

      if (event.uid != null) {
        bool isUserUIDInCache = false;
        if (allSeenUsersInfo != null) {
          allSeenUsersInfo.forEach((key, value) {
            if (value.userUID == event.uid) {
              isUserUIDInCache = true;
            }
          });
        }

        if (isUserUIDInCache) {
          yield UserInfoReturnedFromCache(allSeenUsersInfo[event.uid]!);
          return;
        }

        var result = await FirebaseFirestore.instance
            .collection("users")
            .doc(event.uid)
            .get();

        if (result.exists) {
          var data = result.data();
          User userFound = User(
            userUID: event.uid,
            email: data!['email'],
            isAPPMember: data['isAPPMember'],
            memberCompanyName: data['MemberCompanyName'],
            userFirebaseAuthToken: data['userFirebaseAuthToken'],
            username: data['username'],
            userAvatarURL: data['user_avatar_image_url'],
          );

          allSeenUsersInfo[event.uid!] = userFound;

          yield UserInfoReturnedFromCache(userFound);
          return;
        }
      }
    }
  }

  @override
  UsersRepositoryBlocState fromJson(Map<String, dynamic> json) {
    Map<String, User> tempMap = new Map();

    json.forEach((key, value) {
      tempMap[key] = User.fromJson(jsonDecode(value));
    });

    allSeenUsersInfo = tempMap;
    return UsersInfoLoadedFromStorage();
  }

  @override
  Map<String, dynamic>? toJson(UsersRepositoryBlocState state) {
    if (allSeenUsersInfo != null) {
      Map<String, dynamic> tempMap = allSeenUsersInfo.map((key, value) {
        return MapEntry(key, value.toJson());
      });

      return tempMap;
    }
    return null;
  }
}
