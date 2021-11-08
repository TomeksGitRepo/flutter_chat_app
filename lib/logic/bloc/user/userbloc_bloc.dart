import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:meta/meta.dart';

import 'package:xxxx/dataModels/User.dart' as MyUser;
import 'package:xxxx/utils/common_functions.dart';
import 'package:xxxx/utils/messeging_fcm.dart';

part 'userbloc_event.dart';
part 'userbloc_state.dart';

class UserBloc extends Bloc<UserblocEvent, UserblocState> with HydratedMixin {
  UserData? blocUserData;
  UserBloc({
    this.blocUserData,
  }) : super(blocUserData ?? UserblocInitial()) {
    hydrate();
  }

  @override
  Stream<UserblocState> mapEventToState(
    UserblocEvent event,
  ) async* {
    if (event is CheckUserTokenAndOS) {
      var userEmail = FirebaseAuth.instance.currentUser!.email;
      String? userFirebaseAuthTokenFromDB;
      String? userOSFromDB;
      var result = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: userEmail)
          .get();
      if (result.docs.length != 0) {
        userFirebaseAuthTokenFromDB =
            result.docs.first.data()!['userFirebaseAuthToken'];
        userOSFromDB = result.docs.first.data()!['userPlatform'];
      }
      var userMessagingTokenFromFirebase = await getFirebaseMessagingToken();
      var deviceOS = getPlatform();

      if (userFirebaseAuthTokenFromDB != userMessagingTokenFromFirebase ||
          userOSFromDB != deviceOS) {
        updateUserTokenAndOSinDatabase();
        print(
            'User push notification token invalid or system changed need update. ');
      }
    }
    if (event is GetUserData) {
      var result;
      try {
        result = await FirebaseFirestore.instance
            .collection("users")
            .where("email", isEqualTo: event.email)
            .get();
      } catch (e) {
        print('Error in geting data $e');
      }
      if (result == null) {
        return;
      }

      if (result.docs.length != 0) {
        String userEmail = result.docs.first.data()['email'];
        String userName = result.docs.first.data()['username'];
        String userFirebaseAuthToken =
            result.docs.first.data()['userFirebaseAuthToken'];
        bool isAPPMember = result.docs.first.data()['isAPPMember'];
        String memberCompanyName =
            result.docs.first.data()['MemberCompanyName'] != null
                ? result.docs.first.data()['MemberCompanyName']
                : "";

        blocUserData = UserData(
          MyUser.User(
            email: userEmail,
            username: userName,
            userFirebaseAuthToken: userFirebaseAuthToken,
            isAPPMember: isAPPMember,
            memberCompanyName: memberCompanyName,
          ),
        );

        yield blocUserData!;
      }
    }

    if (event is LogoutUser) {
      yield UserLoggedOut();
    }
  }

  updateUserTokenAndOSinDatabase() async {
    String? userMessagingTokenFromFirebase = await getFirebaseMessagingToken();
    String deviceOS = getPlatform();
    String? userUID = FirebaseAuth.instance.currentUser!.uid;

    updateUserTokenAndIOsInUser(
      userUID: userUID,
      userMessagingToken: userMessagingTokenFromFirebase!,
      deviceOS: deviceOS,
    );

    updateUserTokenAndIOSInChat(
      userUID: userUID,
      userMessagingToken: userMessagingTokenFromFirebase,
      deviceOS: deviceOS,
    );
  }

  updateUserTokenAndIOsInUser(
      {String? userUID, String? userMessagingToken, String? deviceOS}) async {
    await FirebaseFirestore.instance.collection('users').doc(userUID).set({
      'userFirebaseAuthToken': userMessagingToken,
      'userPlatform': deviceOS,
    }, SetOptions(merge: true));
  }

  updateUserTokenAndIOSInChat(
      {@required String? userUID,
      @required String? userMessagingToken,
      @required String? deviceOS}) async {
    var snapshots = await FirebaseFirestore.instance
        .collection('chats')
        .where('usersInvolvedUID.$userUID', isNotEqualTo: null)
        .get();

    print(snapshots.docs.length);

    snapshots.docs.forEach((element) {
      var elementData = element.data();
      elementData!['usersInvolvedUID']
          [userUID] = {'token': userMessagingToken, 'userPlatform': deviceOS};

      FirebaseFirestore.instance
          .collection('chats')
          .doc(element.id)
          .set(elementData, SetOptions(merge: true));
    });
  }

  @override
  UserblocState fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return UserLoggedOut();
    }
    return UserData(MyUser.User.fromJson(json));
  }

  @override
  Map<String, dynamic> toJson(UserblocState state) {
    if (state is UserData) {
      return state.userData.toMap();
    }
    if (state is UserLoggedOut) {
      return {};
    }
    return {};
  }
}
