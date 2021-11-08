import 'package:flutter/material.dart';
import 'package:xxxx/screens/adding_user_to_chat_screen.dart';
import 'package:xxxx/screens/auth_screen.dart';
import 'package:xxxx/screens/chat_screen.dart';
import 'package:xxxx/screens/chats_screen.dart';
import 'package:xxxx/screens/create_chat_screen.dart';
import 'package:xxxx/screens/create_individual_user_chat.dart';
import 'package:xxxx/screens/main_screen.dart';
import 'package:xxxx/screens/settings/group_chat_admin_panel.dart';
import 'package:xxxx/screens/settings_screen.dart';
import 'package:xxxx/screens/website_screen.dart';
import 'package:xxxx/screens/settings/change_company_password_screen.dart';
import 'package:xxxx/screens/show_image_full_screen.dart';

const String PAGE_FIREBASE_TESTS = '/firebase-tests';
const String PAGE_CHAT_MAIN_SCREEN = '/chat-main-screen';
const String PAGE_WEBSITE_WEBVIEW = '/website-webview';
const String PAGE_CHATS_MAIN_SCREEN = '/chats-main-screen';
const String CREATE_CHAT_SCREEN = '/create-chat-screen';
const String ADDING_USER_TO_CHAT_SCREEN = '/add-user-to-chat';
const String AUTH_SCREEN = '/auth-screen';
const String MAIN_APP_SCREEN = '/main-app-screen';
const String ADDING_INVIDUAL_USER_CHAT = '/adding-indyvidual-chat-user';
const String APPLICATION_SETTINGS_SCREEN = '/application_settings';
const String CHANGE_USER_COMPANY_PASSWORD =
    '/change_user_company_password_settings';
const String SHOW_IMAGE_FULL_SCREEN = '/show_image_full_screen';
const String GROUP_CHAT_ADMIN_PANEL_SCREEN = '/group_chat_admin_panel_screen';

Map<String, WidgetBuilder> materialRoutes = {
  MAIN_APP_SCREEN: (context) => MainScreen(),
  PAGE_CHATS_MAIN_SCREEN: (context) => ChatsScreen(),
  PAGE_CHAT_MAIN_SCREEN: (context) =>
      ChatScreen(arguments: ModalRoute.of(context)!.settings.arguments),
  PAGE_WEBSITE_WEBVIEW: (context) => WebsiteScreen(),
  CREATE_CHAT_SCREEN: (context) => CreateChatScreen(),
  ADDING_INVIDUAL_USER_CHAT: (context) => CreateIndividualUserChatScreen(),
  ADDING_USER_TO_CHAT_SCREEN: (context) => AddingUserToChatScreen(
      arguments: ModalRoute.of(context)!.settings.arguments),
  AUTH_SCREEN: (context) => AuthScreen(),
  APPLICATION_SETTINGS_SCREEN: (context) => SettingsScreen(),
  CHANGE_USER_COMPANY_PASSWORD: (context) => ChangeCompanyPasswordScreen(),
  SHOW_IMAGE_FULL_SCREEN: (context) => ShowImageFullScreen(
      imageURL: ModalRoute.of(context)!.settings.arguments.toString()),
  GROUP_CHAT_ADMIN_PANEL_SCREEN: (context) =>
      GroupChatScreen(arguments: ModalRoute.of(context)!.settings.arguments),
};
