import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LastNewsClicDate {
  String? date;

  LastNewsClicDate({this.date});
}

class LatestNewsClickManager {
  Database? _database;
  LastNewsClicDate? _lastNewsClicDate;

  LatestNewsClickManager() {
    init();
  }

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    _database = await openDatabase(
      join(await getDatabasesPath() as String, 'cache_database.db'),
      onOpen: (db) async {
        await db.execute(
            "CREATE TABLE IF NOT EXISTS latest_news_click (latestChatManager TEXT PRIMARY KEY)");
      },
      version: 1,
    );
  }

  Future<String> getlatestNewsClickFromDB() async {
    var latestNewsClick = await _getLatestNewsClickFromDB();
    if (latestNewsClick.isEmpty) {
      return 'No lastNewsClick data';
    }
    return latestNewsClick.first['latestChatManager'];
  }

  Future<void> insertLatestNewsClick(String date) async {
    _lastNewsClicDate = new LastNewsClicDate(date: date);
    await clearDBTable();
    await _insertLastNewsClick(_lastNewsClicDate!);
  }

  Future<void> _insertLastNewsClick(LastNewsClicDate latestNewsClic) async {
    await _database!.insert(
        'latest_news_click', {'latestChatManager': latestNewsClic.date});
  }

  Future<List<Map<String, dynamic>>> _getLatestNewsClickFromDB() async {
    if (_database == null) {
      _database = await openDatabase(
        join(await getDatabasesPath() as String, 'cache_database.db'),
        onOpen: (db) async {
          await db.execute(
              "CREATE TABLE IF NOT EXISTS latest_news_click (latestChatManager TEXT PRIMARY KEY)");
        },
        version: 1,
      );
    }
    //TODO fix this logic so it will not throw errors after first debug cycle
    await _database!.execute(
        "CREATE TABLE IF NOT EXISTS latest_news_click (latestChatManager TEXT PRIMARY KEY)");
    return _database!.query('latest_news_click');
  }

  Future<void> clearDBTable() async {
    await _database!.execute("DROP TABLE IF EXISTS latest_news_click");
    await _database!.execute(
        "CREATE TABLE IF NOT EXISTS latest_news_click (latestChatManager TEXT PRIMARY KEY)");
  }
}
