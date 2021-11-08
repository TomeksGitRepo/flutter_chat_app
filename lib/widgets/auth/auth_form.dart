import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xxxx/logic/bloc/user/userbloc_bloc.dart';
import 'package:xxxx/logic/cubits/passwordtocompany_cubit.dart';
import 'package:xxxx/widgets/pickers/user_image_picker.dart';
import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final bool isLoading;
  String? _errorOnLogging = '';
  final void Function({
    String email,
    String username,
    String password,
    File image,
    bool isLogin,
    bool isAPPMember,
    String memberCompanyName,
    BuildContext ctx,
  }) submitFn;
  AuthForm(this.submitFn, this.isLoading, this._errorOnLogging);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';
  String _companyName = '';
  File? _userImageFile;
  bool _isAPPMember = false;
  String? _tempPassword;
  String? _retypedPassword;

  void _pickedImage(File image) {
    _userImageFile = image;
  }

  void _trySubmit() {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (_userImageFile == null && !_isLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proszę wybierz zdjęcie.'),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );

      return;
    }

    if (isValid) {
      _formKey.currentState!.save();
      if (_isLogin) {
        widget.submitFn(
          email: _userEmail.trim(),
          username: _userName.trim(),
          password: _userPassword.trim(),
          isLogin: _isLogin,
          ctx: context,
          isAPPMember: _isAPPMember,
          memberCompanyName: _companyName,
        );
        return;
      }
      widget.submitFn(
        email: _userEmail.trim(),
        username: _userName.trim(),
        password: _userPassword.trim(),
        image: _userImageFile!,
        isLogin: _isLogin,
        ctx: context,
        isAPPMember: _isAPPMember,
        memberCompanyName: _companyName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PasswordToCompanyCubit(),
      child: Builder(
        builder: (context) => Center(
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
                      if (!_isLogin) UserImagePicker(_pickedImage),
                      TextFormField(
                        key: ValueKey('email'),
                        autocorrect: false,
                        style: widget._errorOnLogging ==
                                'Nie ma takiego użytkownika lub użytkownik został usunięty.'
                            ? TextStyle(
                                color: Colors.red,
                              )
                            : TextStyle(),
                        textCapitalization: TextCapitalization.none,
                        enableSuggestions: false,
                        validator: (value) {
                          if (value!.isEmpty || !value.contains('@')) {
                            return 'Proszę wprowadzić poprawny adres email.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _userEmail = value!;
                        },
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Adres Email",
                        ),
                      ),
                      if (!_isLogin)
                        TextFormField(
                          key: ValueKey('username'),
                          autocorrect: true,
                          textCapitalization: TextCapitalization.words,
                          enableSuggestions: false,
                          validator: (value) {
                            if (value!.isEmpty || value.length < 4) {
                              return 'Proszę o wpisanie minimum 4 znaków.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _userName = value!;
                          },
                          decoration:
                              InputDecoration(labelText: 'Nazwa użytkownika'),
                        ),
                      TextFormField(
                        key: ValueKey('password'),
                        style:
                            widget._errorOnLogging == 'Hasło jest niepoprawne.'
                                ? TextStyle(
                                    color: Colors.red,
                                  )
                                : TextStyle(),
                        validator: (value) {
                          if (value!.isEmpty || value.length < 7) {
                            return 'Hasło musi mieć co najmniej 7 znaków.';
                          }
                          return null;
                        },
                        onChanged: (text) => _tempPassword = text,
                        onSaved: (value) {
                          _userPassword = value!;
                        },
                        decoration: InputDecoration(
                          labelText: 'Hasło',
                        ),
                        obscureText: true,
                      ),
                      if (!_isLogin)
                        TextFormField(
                          key: ValueKey('retyped_password'),
                          style: _tempPassword != _retypedPassword &&
                                  _retypedPassword!.length >=
                                      _tempPassword!.length
                              ? TextStyle(
                                  color: Colors.red,
                                )
                              : TextStyle(),
                          validator: (value) {
                            if (_tempPassword != _retypedPassword) {
                              return 'Hasła nie są identyczne';
                            }
                            return null;
                          },
                          onChanged: (text) {
                            setState(() {
                              _retypedPassword = text;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Hasło',
                          ),
                          obscureText: true,
                        ),
                      SizedBox(
                        height: 12,
                      ),
                      if (!_isLogin) displayPasswordToCompanyInput(context),
                      SizedBox(
                        height: 12,
                      ),
                      if (widget.isLoading) CircularProgressIndicator(),
                      if (!widget.isLoading)
                        RaisedButton(
                          child: Text(_isLogin ? 'Login' : 'Zapisz się'),
                          onPressed: _isLogin == false &&
                                      _tempPassword == _retypedPassword &&
                                      _userImageFile != null ||
                                  _isLogin == true
                              ? _trySubmit
                              : null,
                        ),
                      if (!widget.isLoading)
                        FlatButton(
                          textColor: Theme.of(context).primaryColor,
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                              _isLogin ? 'Stwórz nowe konto' : 'Mam już konto'),
                        ),
                      if (!widget.isLoading)
                        FlatButton(
                          textColor: Theme.of(context).primaryColor,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  displayResetPasswordDialog(context),
                            );
                          },
                          child: Text("Zapomniałeś hasła? Zresetuj je."),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column displayPasswordToCompanyInput(BuildContext context) {
    final passwordToCompanyNameState =
        context.watch<PasswordToCompanyCubit>().state;
    return Column(
      children: [
        Divider(),
        Text('Jeżeli posiadasz hasło dla członków xxxx wpisz je poniżej:'),
        TextFormField(
          key: ValueKey('companyPassword'),
          onChanged: (value) {
            // print('value is $value');
            BlocProvider.of<PasswordToCompanyCubit>(context)
                .getCompanyFromPassword(value);
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

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Nazwa firmy:'),
          Text(passwordToCompanyNameState.companyName),
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
}

Widget displayResetPasswordDialog(BuildContext context) {
  final _auth = FirebaseAuth.instance;
  var _email = '';
  var welcomeText = 'Podaj email w celu zrestartowania hasła';

  return SimpleDialog(
    title: Text('$welcomeText'),
    contentPadding: EdgeInsets.all(20.0),
    children: [
      TextField(
        decoration: InputDecoration(hintText: "Podaj adres email"),
        keyboardType: TextInputType.emailAddress,
        onChanged: (text) {
          _email = text;
        },
      ),
      SizedBox(
        height: 8,
      ),
      FlatButton(
          onPressed: () {
            _auth.setLanguageCode('pl');
            _auth.sendPasswordResetEmail(email: _email).then((_) {
              Navigator.pop(context);
              return showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(
                      'Email z linkiem do resetu hasła został wysłany na podany adres mailowy.'),
                ),
              );
            }).catchError(
              (error) {
                Navigator.pop(context);
                return showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(
                        'Wystąpił problem z resetem hasła.\n\n Sprawdź podany adres email.'),
                  ),
                );
              },
            );
          },
          child: Text('Wyślij'))
    ],
  );
}
