import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/routes.dart';
import 'package:xxxx/utils/autoUpdate/currentAppInfo.dart';
import 'package:xxxx/widgets/settings/setting_item.dart';
import 'package:xxxx/widgets/settings/settings_sections.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CurrentAppInfo? currentAppInfo;
  Bloc? _userBloc; //TODO close this stream when finished
  var resultFromUser = FirebaseAuth.instance.currentUser;
  Icon lockIcon = Icon(Icons.https);
  String compannyPassword = "Hasło firmowe";
  String? compannyPasswordValue = "Wpisz hasło";
  Icon userIcon = Icon(Icons.account_circle);
  String userNameLabel = 'Nazwa użytkownika';

  @override
  void initState() {
    //BlocProvider.of<UserBloc>(context).add(GetUserData(resultFromUser.email));
    super.initState();
  }

  List<SettingItem> settings = [];

  @override
  Widget build(BuildContext context) {
    currentAppInfo ??= CurrentAppInfo(context);
    //TODO use this to display app info  currentAppInfo.printVersion();
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
              child: BlocBuilder<UserBloc, UserblocState>(
                builder: (context, state) {
                  if (state is UserData) {
                    settings.add(SettingItem(
                        userIcon, userNameLabel, state.userData.username));
                    if (state.userData.memberCompanyName != null &&
                        state.userData.memberCompanyName != "") {
                      compannyPasswordValue = state.userData.memberCompanyName;
                      int indexOfSetting = settings.indexWhere(
                          (element) => element.settingName == compannyPassword);
                      if (indexOfSetting != -1) {
                        settings[indexOfSetting] = SettingItem(
                            lockIcon, compannyPassword, compannyPasswordValue);
                      } else {
                        settings.add(SettingItem(
                            lockIcon, compannyPassword, compannyPasswordValue));
                      }

                      return SettingSection(
                          "Informacje o użytkowniku", settings);
                      // debugPrint("User IS member");
                    } else {
                      settings.add(SettingItem(
                          lockIcon, compannyPassword, "Wpisz hasło"));
                      return SettingSection(
                          "Informacje o użytkowniku", settings);
                      // debugPrint("User is NOT member");
                    }
                  }
                  return Text('No user data');
                },
              ),
            ),
          ],
        )));
  }

  @override
  void dispose() {
    if (_userBloc != null) {
      _userBloc!.close();
    }

    super.dispose();
  }
}
