import 'dart:core';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:deru/models/order_model.dart';
import 'dart:convert';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'order_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE orders(
            orderId INTEGER PRIMARY KEY AUTOINCREMENT,
            items TEXT,
            totalAmount REAL,
            customerName TEXT,
            status TEXT,
            timeStamp TEXT
          )
        ''');
      },
    );
  }


  Future<Database> initializeDatabase() async {
    final databasesPath = await database;
    final path = '$databasesPath/orders';
    return openDatabase(path, version: 1);
  }


  Future<void> insertOrder(Order order) async {
    final db = await database;
    final itemsJson = jsonEncode(order.items);
    final now = DateTime.now();
    final timeStampString = now.toIso8601String();



    await db.insert('orders',
        {
          'items': order.items,
          'totalAmount': order.totalAmount,
          'customerName': order.customerName,
          'status': order.status,
          'timeStamp': timeStampString,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Order>> getOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders');
    return List.generate(maps.length, (i) {
      return Order(
        orderId: maps[i]['orderId'],
        items: maps[i]['items'],
        totalAmount: maps[i]['totalAmount'],
        customerName: maps[i]['customerName'],
        status: maps[i]['status'],
        timeStamp: maps[i]['timeStamp'],
      );
    });
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    final db = await database;
    await db.update('orders', {'status': newStatus}, where: 'orderId = ?', whereArgs: [orderId]);
  }


  Future<List<Order>> getStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders', where: 'status =?', whereArgs: [status]);
    return List.generate(maps.length, (i) {
      return Order(
        orderId: maps[i]['orderId'],
        items: maps[i]['items'],
        totalAmount: maps[i]['totalAmount'],
        customerName: maps[i]['customerName'],
        status: maps[i]['status'],
        timeStamp: maps[i]['timeStamp'],
      );
    });
  }

  Future<void> dropDatabase() async {
    final path = join(await getDatabasesPath(), 'order_database.db');
    await deleteDatabase(path);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    final db = await database;
    return await db.query('orders');
  }

  Future<List<Map<String, dynamic>>> status() async {
    final db = await database;
    return await db.query('orders', where: 'status = ?', whereArgs: [0]);
  }
}



