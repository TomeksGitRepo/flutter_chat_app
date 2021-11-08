import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';

class WebsiteScreen extends StatefulWidget {
  @override
  _WebsiteScreenState createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
        gestureNavigationEnabled: true,
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: 'http://xxxx.pl/aktualnosci/'); // url of client's wordpress  website 
  }
}
