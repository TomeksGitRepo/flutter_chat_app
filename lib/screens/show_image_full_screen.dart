import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ShowImageFullScreen extends StatefulWidget {
  String? imageURL;

  ShowImageFullScreen({this.imageURL});

  @override
  _ShowImageFullScreen createState() => _ShowImageFullScreen();
}

class _ShowImageFullScreen extends State<ShowImageFullScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: InkWell(
          child: CachedNetworkImage(
            imageUrl: widget.imageURL!,
            fit: BoxFit.cover,
          ),
          onTap: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
