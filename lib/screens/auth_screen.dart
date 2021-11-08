import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/routes.dart';
import 'package:xxxx/utils/messeging_fcm.dart';
import 'package:xxxx/widgets/auth/auth_form.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  var isLoading = false;
  var _errorOnLogging;
  void _submitAuthForm({
    String? email,
    String? username,
    String? password,
    File? image,
    bool? isLogin,
    bool? isAPPMember,
    String? memberCompanyName,
    BuildContext? ctx,
  }) async {
    UserCredential? authResult;
    try {
      if (isLogin!) {
        try {
          setState(() {
            isLoading = true;
          });
          authResult = await _auth.signInWithEmailAndPassword(
            email: email!,
            password: password!,
          );
          //TODO if login was successful save user and password to database for later logins
          if (authResult != null) {
            BlocProvider.of<UserBloc>(context).add(GetUserData(email));
          }
        } catch (err) {
          // print('Error loging user $err');
          var message = 'Wystąpił błąd, proszę sprawdzić dane.';

          if ((err as FirebaseAuthException).message ==
              "There is no user record corresponding to this identifier. The user may have been deleted.") {
            message =
                "Nie ma takiego użytkownika lub użytkownik został usunięty.";
            setState(() {
              _errorOnLogging = message;
            });
          } else if (err.message ==
              "The password is invalid or the user does not have a password.") {
            message = "Hasło jest niepoprawne.";
            setState(() {
              _errorOnLogging = message;
            });
          } else if (err.message ==
              "The email address is already in use by another account.") {
            message =
                "Podany adres mailowy jest już używany. Prosimy zarejestrować się przy użyciu innego konta.";
          } else if (err.message ==
              'We have blocked all requests from this device due to unusual activity. Try again later.') {
            message =
                'Z powodu nietypowej aktywności zablokowaliśmy te urządzenie. Spróbuj ponownie później';
            setState(() {
              _errorOnLogging = message;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).errorColor,
          ));
          setState(() {
            isLoading = false;
          });
        }

        // Navigator.pushNamed(context, MAIN_APP_SCREEN);
      } else {
        authResult = await _auth.createUserWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_avatar_image')
            .child(authResult.user!.uid + '.jpg');

        await ref.putFile(image!);
        final url = await ref.getDownloadURL();
        var userIdToken = await getFirebaseMessagingToken();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user!.uid)
            .set({
          'username': username,
          'email': email,
          'userFirebaseAuthToken': userIdToken,
          'isAPPMember': isAPPMember,
          'MemberCompanyName': memberCompanyName,
          'user_avatar_image_url': url,
        });

        Navigator.pushNamed(context, MAIN_APP_SCREEN);
      }
    } catch (err) {
      var message = 'Wystąpił błąd, proszę sprawdzić dane.';

      if ((err as FirebaseAuthException).message ==
          "There is no user record corresponding to this identifier. The user may have been deleted.") {
        message = "Nie ma takiego użytkownika lub użytkownik został usunięty.";
      } else if (err.message ==
          "The password is invalid or the user does not have a password.") {
        message = "Hasło jest niepoprawne.";
      } else if (err.message ==
          "The email address is already in use by another account.") {
        message =
            "Podany adres mailowy jest już używany. Prosimy zarejestrować się przy użyciu innego konta.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).errorColor,
      ));
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: AuthForm(_submitAuthForm, isLoading, _errorOnLogging),
    );
  }
}
