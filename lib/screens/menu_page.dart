import 'dart:convert';

import 'package:deru/api_manager.dart';
import 'package:deru/bluetooth_manager.dart';
import 'package:deru/database/database_helper.dart';
import 'package:deru/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

final dbHelper = DatabaseHelper();
final List<String> orderList = [];
BluetoothConnection? _connection;
late Future<Meal> futureMeal;
//List<String> orderList = [];
final double itemWidth = 100.0;
final double itemHeight = 150.0;
//final List<String> orderList = [];

int quantity = 0;

class Cart {
  String meal;
  int quantity;

  Cart({required this.meal, required this.quantity});

  @override
  String toString() {
    return 'Order(meal: $meal, quantity: $quantity)';
  }
}

List<Cart> carrt = [];

void addOrder(String meal, int quantity) {
  bool exists = carrt.any((cart) => cart.meal == meal);

  if (exists) {
    int index = carrt.indexWhere((cart) => cart.meal == meal);
    carrt[index].quantity += quantity;

    if (carrt[index].quantity == 0) {
      carrt.removeAt(index);
    }
  } else {
    if (quantity > 0) {
      carrt.add(Cart(meal: meal, quantity: quantity));
    }
  }
}

int getQuantity(String meal) {
  for (var cart in carrt) {
    if (cart.meal == meal) {
      return cart.quantity;
    }
  }
  return 0;
}


Future<void> insertOrderIntoDatabase(Order order) async {
  //final db = await DatabaseHelper.instance.database;

  Map<String, dynamic> orderData = {
    'order_id': 'your_order_id',
    'customer_name': 'your_customer_name',
    'order_date': DateTime.now().toString(),
  };


  print('Order inserted successfully!');
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Stack(
        children: [
          MenuGridView(),

          OrderButton(),
        ],
      ),
    );
  }
}

class MenuGridView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 100.0 / 150.0,
      ),
      itemCount: 20,
      itemBuilder: (BuildContext context, int index) {
        return MealCard(index: index);
      },
    );
  }
}

class MealCard extends StatelessWidget {
  final int index;

  MealCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final ApiManager apiManager = ApiManager();
    final futureMeal = apiManager.fetchMeal();

    return Container(
      margin: const EdgeInsets.all(4.0),
      child: FutureBuilder<Meal>(
        future: futureMeal,
        builder: (context, snapshot) {
          final ApiManager apiManager = ApiManager();
          final futureMeal = apiManager.fetchMeal();
          return Container(
            //color: Colors.blue, // Customize the item's appearance
            margin: const EdgeInsets.all(4.0),
            child: FutureBuilder<Meal>(
              future: futureMeal,
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
                      Card(
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => MealDetailsBottomSheet(meal: snapshot.data!, updateOrderButton: _OrderButtonState().updateVisibility,),
                              );

                            },
                            child: SizedBox(
                              width: 300,
                              height: 240,
                              child: Column(
                                children: [
                                  Image.network(imageUrl),
                                  Text(mealName,
                                    style: const TextStyle(
                                      //fontSize: 18,
                                      fontWeight: FontWeight.bold,),),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '125',
                                        style: TextStyle(
                                          //fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                            )
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return const Column(
                  children: [
                    CircularProgressIndicator(),
                  ],
                );
              },
            ),
          );
        },

      ),
    );

  }
}

class MealDetailsBottomSheet extends StatefulWidget {
  final Meal meal;
  final void Function() updateOrderButton;

  MealDetailsBottomSheet({required this.meal, required this.updateOrderButton});


  @override
  _MealDetailsBottomSheetState createState() => _MealDetailsBottomSheetState();
}

class _MealDetailsBottomSheetState extends State<MealDetailsBottomSheet> {
  int quantity = 0;

  @override
  void initState() {
    super.initState();
    quantity = getQuantity(widget.meal.strMeal);
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 450,
      child: Stack(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.meal.strMealThumb),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.meal.strMeal,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Meal ID: ${widget.meal.idMeal}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Meal Description: ${(widget.meal.strInstructions).substring(0, 200)}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Meal Price: 250',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 0) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black,

                    ),
                    child: TextButton(
                      child: Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        addOrder(widget.meal.strMeal, (quantity - getQuantity(widget.meal.strMeal)));

                        print(carrt);
                        Navigator.pop(context);
                        setState(() {});
                        //widget.updateOrderButton();
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderButton extends StatefulWidget {
  @override
  _OrderButtonState createState() => _OrderButtonState();
}

class _OrderButtonState extends State<OrderButton> {
  void updateVisibility() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: carrt.isEmpty,
      child: Positioned(
        bottom: 16,
        right: 16,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: FloatingActionButton(
            onPressed: () async {
              if (carrt.isEmpty) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Cart is empty'),
                      content: Text('Please add some items to the cart.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderDetailsScreen()),
                );
              }
            },
            child: Icon(
              carrt.isEmpty? Icons.add : Icons.arrow_forward,
              //color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class Menu extends State<MenuPage> {
  //const Menu({super.key});


  final dbHelper = DatabaseHelper();

  final List<String> orderList = [];
  BluetoothConnection? _connection;
  late Future<Meal> futureMeal;
  //List<String> orderList = [];
  final double itemWidth = 100.0;
  final double itemHeight = 150.0;



  Future<void> printTableData() async {
    final allRows = await dbHelper.queryAllRows();
    print('Table data:');
    for (final row in allRows) {
      print(row);
    }
  }

  void addToStringList(String value) {
    orderList.add(value);
    //todos[0].orderList.add(value);
  }




  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper();
    final bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Stack(
        children: [
          Stack(
            children: [
              GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemCount: 20,
                itemBuilder: (BuildContext context, int index) {
                  final ApiManager apiManager = ApiManager();
                  final futureMeal = apiManager.fetchMeal();
                  return Container(
                    //color: Colors.blue, // Customize the item's appearance
                    margin: const EdgeInsets.all(4.0),
                    child: FutureBuilder<Meal>(
                      future: futureMeal,
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
                              Card(
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                    onTap: () {

                                      showModalBottomSheet<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return SizedBox(
                                            height: 450,
                                            child: Stack(
                                              children: [
                                                Container(
                                                  height: 300,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(imageUrl),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.only(
                                                        topLeft: Radius.circular(16),
                                                        topRight: Radius.circular(16),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          mealName,
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Meal ID: $mealId',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Meal Description: ${(snapshot.data!.strInstructions).substring(0, 200)}',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Meal Price: 250',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        /*ElevatedButton(
                                                        child: const Text('Close BottomSheet'),
                                                        onPressed: () {
                                                          addToStringList(mealId);
                                                          print(orderList);
                                                          Navigator.pop(context);
                                                          setState(() {});
                                                        },
                                                      ),*/


                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            IconButton(
                                                              icon: Icon(Icons.remove),
                                                              onPressed: () {
                                                                if (quantity > 0) {
                                                                  setState(() {
                                                                    quantity--;
                                                                  });
                                                                }
                                                              },
                                                            ),
                                                            Text(
                                                              '$quantity',
                                                              style: TextStyle(
                                                                fontSize: 24,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(Icons.add),
                                                              onPressed: () {
                                                                setState(() {
                                                                  quantity++;
                                                                });
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        ElevatedButton(
                                                          child: const Text('Add to Cart'),
                                                          onPressed: () {
                                                            addToStringList(mealId, /*quantity*/);
                                                            print(orderList);
                                                            Navigator.pop(context);
                                                            setState(() {});
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                      debugPrint('Card tapped.');
                                    },
                                    child: SizedBox(
                                      width: 300,
                                      height: 250,
                                      child: Column(
                                        children: [
                                          Image.network(imageUrl),
                                          Text(mealName,
                                            style: TextStyle(
                                              //fontSize: 18,
                                              fontWeight: FontWeight.bold,),),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '125',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                ),
                              ),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        }
                        return const Column(
                          children: [
                            CircularProgressIndicator(),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              Visibility(
                visible: orderList.isEmpty,
                child: Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
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
                      //await dbHelper.insertOrder(newOrder);
                      bluetoothManager.sendData('Pedro       lklklklk*Orden: 102');
                      print('Pridwadaw:');
                      print(orderList);
                      //Navigator.pushNamed(context, '/orders', arguments: orderList);
                      /*Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SecondRoute()),
                      );*/
                      await printTableData();
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}


class OrderDetailsScreen extends StatefulWidget {
  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order ID:', style: TextStyle(fontSize: 16)),
                    Text('2', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Date:', style: TextStyle(fontSize: 16)),
                    Text('exrdcty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 16),

                Text(
                  'Cart Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: carrt.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(carrt[index].meal),
                          subtitle: Text('Quantity: ${carrt[index].quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('255'),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    carrt.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            /*showModalBottomSheet(
                              context: context,
                              builder: (context) => MealDetailsBottomSheet(meal: snapshot.data!, updateOrderButton: _OrderButtonState().updateVisibility,),
                            );*/
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  List<String> items = [];

                  for (Cart item in carrt) {
                    for (int i = 0; i < item.quantity; i++) {
                      items.add(item.meal);
                    }
                  }
                  final itemsJson = jsonEncode(items);
                  final now = DateTime.now();
                  final timeStampString = now.toIso8601String();
                  Order order = Order(
                    orderId: 1,
                    items: itemsJson,
                    totalAmount: 100.0,
                    customerName: '5ecr',
                    status: '0',
                    timeStamp: timeStampString,
                  );
                  print(items);
                  await dbHelper.insertOrder(order);
                  final allRows = await dbHelper.queryAllRows();

                  print('Table data:');
                  for (final row in allRows) {
                    print(row);
                  }
                  Navigator.pushNamed(context, '/orders', arguments: orderList);

                },
                child: Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

