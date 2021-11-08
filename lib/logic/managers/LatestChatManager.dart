import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Chat {
  String? id;

  Chat({this.id});
}

class LatestChatManager {
  Database? _database;
  Chat? _chat;

  LatestChatManager() {
    init();
  }

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    _database = await openDatabase(
      join(await getDatabasesPath() as String, 'cache_database.db'),
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE latest_chats (chatID TEXT PRIMARY KEY)");
      },
      version: 1,
    );
  }

  Future<String> getlatestChatIDFromDB() async {
    var latestChat = await _getLatestChatFromDB();
    if (latestChat.isEmpty) {
      return 'No lastChat data';
    } else {
      clearDBTable();
    }
    return latestChat[0]['chatID'];
  }

  Future<void> insertLatestChatID(String latestChatID) async {
    _chat = new Chat(id: latestChatID);
    await clearDBTable();
    print('IN insertLatestChatID');
    await insertLastChat(_chat!);
  }

  Future<void> insertLastChat(Chat chat) async {
    print('IN insertLastChat');
    await _database!.execute(
        "CREATE TABLE IF NOT EXISTS latest_chats (chatID TEXT PRIMARY KEY)");
    await _database!.insert('latest_chats', {'chatID': chat.id});
    print('AFTER insertLastChat');
  }

  Future<List<Map<String, dynamic>>> _getLatestChatFromDB() async {
    await _database!.execute(
        "CREATE TABLE IF NOT EXISTS latest_chats (chatID TEXT PRIMARY KEY)");
    return _database!.query('latest_chats');
    ;
  }

  Future<void> clearDBTable() async {
    await _database!.execute("DROP TABLE IF EXISTS latest_chats");
    await _database!
        .execute("CREATE TABLE latest_chats (chatID TEXT PRIMARY KEY)");
  }
}
