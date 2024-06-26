import 'package:flutter/foundation.dart';
import 'package:restaurantbooking/JsonModels/booking.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:restaurantbooking/JsonModels/session.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'restaurantpack.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        userid INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        phone INTEGER,
        username TEXT,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE menubook (
        bookid INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER,
        bookdate DATE,
        booktime TIME,
        eventdate DATE,
        eventtime TIME,
        menupackage TEXT,
        numguest INTEGER,
        packageprice DOUBLE,
        FOREIGN KEY (userid) REFERENCES users (userid)
      )
    ''');

    await db.execute('''
      CREATE TABLE administrator (
        adminid INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        password TEXT
      )
    ''');
  }

  Future<void> insertUser(Users user) async {
    final db = await database;
    try {
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting user: $e');
      }
    }
  }

  Future<Users> getUserById(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'userid = ?',
      whereArgs: [userId],
    );
    if (results.isNotEmpty) {
      return Users.fromMap(results.first);
    }
    throw Exception('User not found');
  }

  Future<int> getUserIdByUsername(String username) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (results.isNotEmpty) {
      return results.first['userid'];
    }
    return -1; // Or handle error accordingly
  }
  Future<void> deleteBooking(int bookId) async {
    final db = await database;
    try {
      await db.delete(
        'menubook',
        where: 'bookid = ?',
        whereArgs: [bookId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting booking: $e');
      }
      throw Exception('Failed to delete booking');
    }
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;
    try {
      await db.delete(
        'users',
        where: 'userid = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user: $e');
      }
    }
  }

  Future<void> insertBooking(
      int userId,
      DateTime bookDateTime,
      DateTime eventDateTime,
      String menuPackage,
      int numGuest,
      double packagePrice) async {
    final db = await database;
    await db.insert(
      'menubook',
      {
        'userid': userId,
        'bookdate': DateFormat('yyyy-MM-dd').format(bookDateTime),
        'booktime': DateFormat('HH:mm:ss').format(bookDateTime),
        'eventdate': DateFormat('yyyy-MM-dd').format(eventDateTime),
        'eventtime': DateFormat('HH:mm:ss').format(eventDateTime),
        'menupackage': menuPackage,
        'numguest': numGuest,
        'packageprice': packagePrice,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MenuBook>> getAllMenuBookings() async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query('menubook');
    List<MenuBook> bookingList = [];
    for (var map in results) {
      bookingList.add(MenuBook.fromMap(map));
    }
    return bookingList;
  }

  Future<void> updateBooking(
      int bookId,
      String menuPackage,
      DateTime eventDateTime,
      int numGuest,
      double packagePrice,
      ) async {
    final db = await database;
    await db.update(
      'menubook',
      {
        'menupackage': menuPackage,
        'eventdate': DateFormat('yyyy-MM-dd').format(eventDateTime),
        'eventtime': DateFormat('HH:mm:ss').format(eventDateTime), // Correctly format time
        'numguest': numGuest,
        'packageprice': packagePrice,
      },
      where: 'bookid = ?',
      whereArgs: [bookId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MenuBook>> getUserMenuBookings(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'menubook',
      where: 'userid = ?',
      whereArgs: [userId],
    );
    List<MenuBook> bookingList = [];
    for (var map in results) {
      bookingList.add(MenuBook.fromMap(map));
    }
    return bookingList;
  }

  Future<bool> login(Users user) async {
    final db = await database;

    // Check Password
    var result = await db.rawQuery(
        "SELECT * from users where username = ? AND password = ?",
        [user.username, user.password]);

    return result.isNotEmpty;
  }

  Future<int> signup(Users user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  // Update user details
  Future<void> updateUsers(Users user) async {
    final db = await database;
    try {
      await db.update(
        'users',
        user.toMap(),
        where: 'userid = ?',
        whereArgs: [user.userid],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
    }
  }

  // Admin Login
  Future<bool> isAdmin(String username) async {
    final db = await database;
    var result = await db.query(
      'administrator',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  // Check Admin Password
  Future<bool> checkAdminPassword(String username, String password) async {
    final db = await database;
    var result = await db.query(
      'administrator',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty;
  }

  // Insert Admin Account into database
  Future<void> insertAdmin(String username, String password) async {
    final db = await database;
    await db.insert(
      'administrator',
      {
        'username': username,
        'password': password,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Users>> getAllUsers() async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query('users');
    List<Users> userList = [];
    for (var map in results) {
      userList.add(Users.fromMap(map));
    }
    return userList;
  }
}