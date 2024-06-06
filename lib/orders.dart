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
    final orderList = ModalRoute.of(context)?.settings.arguments as List<String>?;
    final dbHelper = DatabaseHelper();
    //final orderList = ModalRoute.of(context)!settings.arguments as List<MyGridView>;


    //dbHelper.insertOrder('0' as Order);

    Future<void> printTableData() async {
      final allRows = await dbHelper.status();
      print('Table data status:');
      for (final row in allRows) {
        print(row); // Print each row (map) to the console
      }
    }


    print(orderList);
    printTableData();
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(
                    icon: Icon(Icons.directions_car)),
                Tab(icon: Icon(Icons.directions_transit)),
                Tab(icon: Icon(Icons.directions_bike)),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: const TabBarView(
            children: [
              MealList(),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_car),
            ],
          ),
        ),
      ),
    );
  }
}

class MealList extends StatelessWidget {
  const MealList({super.key});


Future<List<Order>> _fetchOrders() async {
  final dbHelper = DatabaseHelper();
  return await dbHelper.getStatus('0');
}

@override
Widget build(BuildContext context) {
  return FutureBuilder<List<Order>>(
    future: _fetchOrders(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator(); // Show a loading indicator
      } else if (snapshot.hasError) {
        return const Text('Error fetching data'); // Handle error case
      } else if (!snapshot.hasData) {
        return const Text('No data available'); // Handle no data case
      } else {
        final mealNames = snapshot.data!;

        return ListView.builder(
          itemCount: mealNames.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text('Orden: ') ,
                subtitle: Text(mealNames[index].items),
              // Add any other customization (e.g., onTap, subtitle, etc.) as needed
            );
          },
        );
      }
    },
  );
}
}
