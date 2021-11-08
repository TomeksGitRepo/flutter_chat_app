import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

class CurrentAppInfo {
  PackageInfo? packageInfo;
  String? version;
  String? currentVersion;
  String? linkToLatesVersion;
  final checkingURL = 'http://xxxx.pl/aplikacja-mobilna/';
  dynamic context;

  CurrentAppInfo(this.context) {
    init();
  }

  init() async {
    packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo!.version;
    await getAppCurrentVersionAndLink();
    checkIfUpdateAvible();
  }

  printVersion() {
    print("Current app version is: $version");
  }

  getAppCurrentVersionAndLink() async {
    var response = await http.get(Uri.parse(checkingURL));
    const start = "Ostatnia wersja:";
    const end = "Starsze wersje:";
    final getDataContaingVersionAndLinkToIt =
        getSubstringBetweenPatern(response.body, start: start, end: end);
    RegExp exp = new RegExp(r'\d.\d.\d');
    String? matches = exp.stringMatch(getDataContaingVersionAndLinkToIt);
    currentVersion = matches;
    String linkToVersion = getSubstringBetweenPatern(
        getDataContaingVersionAndLinkToIt,
        start: '"',
        end: '"');
    linkToLatesVersion = linkToVersion;
  }

  getSubstringBetweenPatern(String source, {start: String, end: String}) {
    final startIndex = source.indexOf(start);
    final endIndex = source.indexOf(end, (startIndex + start.length) as int);

    return source.substring((startIndex + start.length) as int, endIndex);
  }

  getApplication() async {
    if (Platform.isAndroid) {
      if (await canLaunch(checkingURL)) {
        await launch(checkingURL);
      } else {
        throw 'Could not launch $linkToLatesVersion';
      }
    }
  }

  checkIfUpdateAvible() {
    if (version != currentVersion) {
      showMyDialog();
    }
  }

  Future<void> showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nowa wersja aplikacji'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Nowa wersja aplikacji jest gotowa do pobrania. Dalsze korzystanie z nieakutalnej aplikacji nie jest wskazane.'),
                Text('Pobierz nową wersję aplikacji.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Pobierz'),
              onPressed: () {
                getApplication();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
