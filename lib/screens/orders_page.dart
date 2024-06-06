import 'dart:convert';

import 'package:deru/database/database_helper.dart';
import 'package:deru/menu.dart';
import 'package:deru/models/order_model.dart';
import 'package:flutter/material.dart';

class OrderArguments {

  OrderArguments(this.orderList);
  final List<String> orderList;

//OrderArguments(this.orderList);
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    //...

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            bottom: const TabBar(
              tabs: [
                Tab(
                    icon: Icon(Icons.hourglass_empty)),
                Tab(icon: Icon(Icons.check_circle)),
                //Tab(icon: Icon(Icons.directions_bike)),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: const TabBarView(
            children: [
              MealList(status: '0'),
              MealList(status: '1'),
              //Icon(Icons.directions_car),
            ],
          ),
        ),
      ),
    );
  }
}

class MealList extends StatelessWidget {
  final String status;

  const MealList({super.key, required this.status});

  Future<List<Order>> _fetchOrders() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: _fetchOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error fetching data');
        } else if (!snapshot.hasData) {
          return const Text('No data available');
        } else {
          final mealNames = snapshot.data!;

          return ListView.builder(
            itemCount: mealNames.length,
            itemBuilder: (context, index) {
              List<String> itemList = (jsonDecode(mealNames[index].items) as List<dynamic>).map((e) => e as String).toList();
              return ExpansionTile(
                title: Text('Order ${index + 1}'),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itemList.length,
                    itemBuilder: (context, itemIndex) {
                      return ListTile(
                        title: Text(itemList[itemIndex]),
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
}