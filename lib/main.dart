import 'package:deru/bluetooth_manager.dart';
//import 'package:deru/menu.dart';
//import 'package:deru/orders.dart';
import 'package:flutter/material.dart';
import 'package:deru/main_page.dart';
import 'package:deru/screens/start_page.dart';
import 'package:deru/screens/menu_page.dart';
import 'package:deru/screens/orders_page.dart';


import 'package:provider/provider.dart';

void main() async {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    //return MaterialApp(

    // );
    return ChangeNotifierProvider(
      create: (context) => BluetoothManager() ,
      //create: (context) => ApiManager(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        debugShowCheckedModeBanner: false,
        initialRoute: '/menu', // Set the initial route (optional)
        routes: {
          //'/': (context) => const StartPage(), // Main page
          '/menu': (context) => const MenuPage(), // Menu page
          '/orders': (context) => const OrdersPage(), // Orders page
        },
      ),
    );
  }
}