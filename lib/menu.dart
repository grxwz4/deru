import 'dart:convert';

import 'package:deru/bluetooth_manager.dart';
import 'package:deru/main_page.dart';

import 'package:deru/database/database_helper.dart';
import 'package:deru/menu.dart';
import 'package:deru/models/order_model.dart';
import 'package:deru/orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';


class MenuPage extends StatelessWidget {
  const MenuPage({super.key});


  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper();
    final List<String> orderList = [];

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Stack(
        children: [
          MyGridView(orderList: [],), // Your grid view content
          //_butt().
        ],
      ),
    );
  }
}

Future<Food> fetchFood() async {
  final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'));
  if (response.statusCode == 200) {
    return Food.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to load food');
  }
}


class Food {
  final String idMeal;
  final String strMeal;
  final String strMealThumb;

  const Food({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('meals') && json['meals'] is List) {
      final meal = json['meals'][0];
      if (meal is Map<String, dynamic> && meal.containsKey('idMeal') && meal.containsKey('strMeal')) {
        return Food(
          idMeal: meal['idMeal'] as String,
          strMeal: meal['strMeal'] as String,
          strMealThumb: meal['strMealThumb'] as String,
        );
      }
    }
    throw const FormatException('Failed to load meal.');
  }
}

class MyGridView extends StatelessWidget {
  BluetoothConnection? _connection;
  late Future<Food> futureFood;
  List<String> orderList = [];
  final double itemWidth = 100.0; // Desired width for each item
  final double itemHeight = 150.0;

  MyGridView({required this.orderList});

  void addToStringList(String value) {

    orderList.add(value);

  }

  final dbHelper = DatabaseHelper();

  Future<void> printTableData() async {
    final allRows = await dbHelper.queryAllRows();
    print('Table data:');
    for (final row in allRows) {
      print(row);
    }
  }




  @override
  Widget build(BuildContext context) {
    //final futureFood = fetchFood();
    final bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
    return Stack(
      children: [
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: itemWidth / itemHeight, // Set your desired aspect ratio
          ),
          itemBuilder: (BuildContext context, int index) {
            final futureFood = fetchFood();

            return Container(
              //color: Colors.blue, // Customize the item's appearance
              margin: const EdgeInsets.all(4.0),
              child: FutureBuilder<Food>(
                future: futureFood,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final mealName = snapshot.data!.strMeal;
                    final mealId = snapshot.data!.idMeal;
                    final truncatedName = mealName.length > 20
                        ? '${mealName.substring(0, 20)}...'
                        : mealName;
                    final imageUrl = snapshot.data!.strMealThumb;

                    return Column(
                      children: [
                        Image.network(imageUrl),
                        Text(truncatedName),
                        ElevatedButton(
                          onPressed: () {
                            addToStringList(mealId);
                            //Navigator.pushNamed(context, '/orders', arguments: orderList);
                            print(orderList);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
            );
          },
        ),
        Positioned(
          bottom: 16, // Adjust the value to position the button as desired
          right: 16, // Adjust the value to position the button as desired
          child: FloatingActionButton(
            onPressed: () async {
              // Add your button action here
              final itemsJson = jsonEncode(orderList);
              final now = DateTime.now();
              final timeStampString = now.toIso8601String();
              final newOrder = Order(
                orderId: 0,
                items: itemsJson,
                totalAmount: 130,
                customerName: 'dcerut',
                status: '0',
                timeStamp: timeStampString,
              );

// Insert the new pet (the database will assign an ID)
              await dbHelper.insertOrder(newOrder);
              //if (_connection?.isConnected ?? false) {
              bluetoothManager.sendData('Pedro       lklklklk*Orden: 102');
              print('Pridwadaw:');
              print(orderList);
              Navigator.pushNamed(context, '/orders', arguments: orderList);

              //}
              await printTableData();


            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

}


