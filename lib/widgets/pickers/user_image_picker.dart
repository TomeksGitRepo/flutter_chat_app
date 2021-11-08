import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UserImagePicker extends StatefulWidget {
  UserImagePicker(this.imagePickFn);
  final void Function(File pickedImage) imagePickFn;

  @override
  _UserImagePickerState createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? _pickedImage;

  void _pickImage({@required bool? fromCamera}) async {
    final picker = ImagePicker();
    ImageSource source;
    if (fromCamera!) {
      source = ImageSource.camera;
    } else {
      source = ImageSource.gallery;
    }

    final pickedImage = await picker.getImage(
      source: source,
      imageQuality: 50,
      maxWidth: 150,
    );
    if (pickedImage == null) {
      return;
    }
    final pickedImageFile = File(pickedImage.path);
    setState(() {
      _pickedImage = pickedImageFile;
    });
    widget.imagePickFn(pickedImageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Wybierz zdjęcie',
            style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold),
          ),
        ),
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
          backgroundImage:
              _pickedImage != null ? FileImage(_pickedImage!) : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlatButton.icon(
              textColor: Theme.of(context).primaryColor,
              onPressed: () {
                _pickImage(fromCamera: true);
              },
              icon: Icon(Icons.photo_camera),
              label: Text('Aparat'),
            ),
            FlatButton.icon(
              textColor: Theme.of(context).primaryColor,
              onPressed: () {
                _pickImage(fromCamera: false);
              },
              icon: Icon(Icons.image),
              label: Text('Galeria'),
            ),
          ],
        )
      ],
    );
  }
}
