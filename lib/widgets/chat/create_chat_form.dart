import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';

class CreateChatForm extends StatefulWidget {
  final void Function(
    String chatName,
    bool isGroupChat,
    String userUID,
    BuildContext ctx,
  ) submitFn;
  final bool isLoading;

  CreateChatForm(this.submitFn, this.isLoading);

  @override
  _CreateChatFormState createState() => _CreateChatFormState();
}

class _CreateChatFormState extends State<CreateChatForm> {
  final _formKey = GlobalKey<FormState>();
  String _chatName = '';
  var _isGroupChat = false;
  String _userUID = '';

  @override
  void initState() {
    super.initState();
    getUserUID();
  }

  void _trySubmit() {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      widget.submitFn(_chatName.trim(), _isGroupChat, _userUID, context);
    }
  }

  getUserUID() async {
    User userInstance = FirebaseAuth.instance.currentUser!;
    String userID = userInstance.uid;
    _userUID = userID;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Utwórz nowy indywidualny',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Theme.of(context).primaryColor))
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  RaisedButton(
                    child: Text('Utwórz czat indywidualny'),
                    onPressed: () => Navigator.pushNamed(context,
                        ADDING_INVIDUAL_USER_CHAT), //TODO display users
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Utwórz nowy chat grupowy',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Theme.of(context).primaryColor))
                    ],
                  ),
                  TextFormField(
                    key: ValueKey('chatName'),
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    enableSuggestions: false,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Proszę wprowadzić nazwę chatu.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _chatName = value!;
                    },
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: "Nazwa Czatu",
                    ),
                  ),
                  // SwitchListTile(
                  //   title: const Text('Czy to jest czat grupowy?'),
                  //   value: _isGroupChat,
                  //   key: ValueKey('isGroupChat'),
                  //   onChanged: (bool value) => setState(() {
                  //     _isGroupChat = value;
                  //   }),
                  // ),
                  // SizedBox(
                  //   height: 12,
                  // ),
                  if (widget.isLoading) CircularProgressIndicator(),
                  if (!widget.isLoading)
                    RaisedButton(
                      child: Text('Utwórz czat groupowy'),
                      onPressed: () {
                        _isGroupChat = true;
                        _trySubmit();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
