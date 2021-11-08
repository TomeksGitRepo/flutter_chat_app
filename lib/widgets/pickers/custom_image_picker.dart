import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomImagePicker extends StatefulWidget {
  final void Function(File pickedImage) imagePickFn;

  CustomImagePicker(this.imagePickFn);

  @override
  _CustomImagePickerState createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
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

    final pickedImageFile = File(pickedImage?.path as String);
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
