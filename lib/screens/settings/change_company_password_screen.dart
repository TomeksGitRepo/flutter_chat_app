import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/routes.dart';
import '../../logic/cubits/passwordtocompany_cubit.dart';

class ChangeCompanyPasswordScreen extends StatefulWidget {
  @override
  _ChangeCompanyPasswordScreenState createState() =>
      _ChangeCompanyPasswordScreenState();
}

class _ChangeCompanyPasswordScreenState
    extends State<ChangeCompanyPasswordScreen> {
  var resultFromUser = FirebaseAuth.instance.currentUser;
  Icon lockIcon = Icon(Icons.https);
  String compannyPassword = "Hasło firmowe";
  String? compannyPasswordValue = "Wpisz hasło";
  bool? _isAPPMember;
  String? _companyName;
  UserBloc? userBloc;

  Column displayPasswordToCompanyInput(PasswordToCompanyCubit passwordCubit) {
    final passwordToCompanyNameState = passwordCubit.state;
    return Column(
      children: [
        Divider(),
        Text('Jeżeli posiadasz hasło dla członków xxxx wpisz je poniżej:'),
        TextFormField(
          key: ValueKey('companyPassword'),
          onChanged: (value) {
            // print('value is $value');
            passwordCubit.getCompanyFromPassword(value);
          },
          decoration: InputDecoration(
            labelText: 'Firmowe hasło',
          ),
        ),
        processPasswordToCompanyNameCubic(passwordToCompanyNameState),
      ],
    );
  }

  Widget processPasswordToCompanyNameCubic(
      PasswordToCompanyState passwordToCompanyNameState) {
    if (passwordToCompanyNameState is PasswordToCompanyLoading) {
      return Text('Wczytywanie firmy...');
    } else if (passwordToCompanyNameState is PasswordToCompanyCorrect) {
      _isAPPMember = true;
      _companyName = passwordToCompanyNameState.companyName;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nazwa firmy:'),
              Text(passwordToCompanyNameState.companyName),
            ],
          ),
          FlatButton(
              onPressed: () {
                updateUserInDB(resultFromUser!.email!,
                    passwordToCompanyNameState.companyName);
              },
              child: Text("Wyślij"))
        ],
      );
    } else if (passwordToCompanyNameState is PasswordToCompanyIncorrect) {
      _isAPPMember = false;
      _companyName = '';
      return Text('Hasło niepoprawne.');
    } else if (passwordToCompanyNameState is PasswordToCompanyNotInitated) {
      return Text('');
    }
    return Text('');
  }

  updateUserInDB(String useremail, String companyName) async {
    FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: useremail)
        .get()
        .then((doc) async {
      var result = doc.docs.first.data();
      result!["isAPPMember"] = true;
      result["memberCompanyName"] = companyName;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doc.docs.first.id)
          .set(result);
      userBloc!.add(GetUserData(useremail));
      Navigator.pop(context);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    userBloc!.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    userBloc = BlocProvider.of<UserBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia'),
        actions: [
          DropdownButton(
            underline: Container(),
            icon: Icon(Icons.more_vert,
                color: Theme.of(context).primaryIconTheme.color),
            items: [
              DropdownMenuItem(
                child: Container(
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app),
                      SizedBox(
                        width: 8,
                      ),
                      Text('Wyloguj'),
                    ],
                  ),
                ),
                value: 'logout',
              )
            ],
            onChanged: (itemIdentifier) {
              if (itemIdentifier == 'logout') {
                BlocProvider.of<UserBloc>(context).add(LogoutUser(context));
              }
            },
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<PasswordToCompanyCubit>(
                      create: (context) => PasswordToCompanyCubit()),
                ],
                child: BlocBuilder<UserBloc, UserblocState>(
                    builder: (listenerContext, state) {
                  if (state is UserData) {
                    if (state.userData.memberCompanyName != null &&
                        state.userData.memberCompanyName != "") {
                      compannyPasswordValue = state.userData.memberCompanyName;

                      return Text("Użytkownik jest członkiem xxxx");
                      // debugPrint("User IS member");
                    } else {
                      return Builder(builder: (context) {
                        var passwordToCompanyCubit =
                            context.watch<PasswordToCompanyCubit>();
                        PasswordToCompanyCorrect? companyName;
                        if (passwordToCompanyCubit is PasswordToCompanyCorrect)
                          companyName = passwordToCompanyCubit
                              as PasswordToCompanyCorrect;
                        return Column(
                          children: [
                            if (passwordToCompanyCubit
                                is PasswordToCompanyCorrect)
                              Text(
                                  'Hasło poprawne!!! Nazwa firmy ${companyName!.companyName}'),
                            Text('Wprowadź hasło firmowe:'),
                            displayPasswordToCompanyInput(
                              passwordToCompanyCubit,
                            ),
                          ],
                        );
                      });
                    }
                  }
                  return Text('No user data');
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
