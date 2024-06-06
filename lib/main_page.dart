import 'dart:convert';
import 'package:deru/action_button.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:deru/bluetooth_manager.dart';
import 'package:provider/provider.dart';



class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
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

  const Food({
    required this.idMeal,
    required this.strMeal,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('meals') && json['meals'] is List) {
      final meal = json['meals'][0];
      if (meal is Map<String, dynamic> && meal.containsKey('idMeal') && meal.containsKey('strMeal')) {
        return Food(
          idMeal: meal['idMeal'] as String,
          strMeal: meal['strMeal'] as String,
        );
      }
    }
    throw const FormatException('Failed to load meal.');
  }
}



class _MainPageState extends State<MainPage> {
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  int times = 0;

  late Future<Food> futureFood;
  List<String> orderList = [];

  void _getDevices() async {
    var res = await _bluetooth.getBondedDevices();
    setState(() => _devices = res);
  }

  void _receiveData() {
    _connection?.input?.listen((event) {
      if (String.fromCharCodes(event) == "p") {
        setState(() => times = times + 1);
      }
    });
  }

  void _sendData(String data) {
    if (_connection?.isConnected ?? false) {
      //print(_connection);
      _connection?.output.add(ascii.encode(data));
    }
  }

  void _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  @override
  void initState() {
    super.initState();

    futureFood = fetchFood();

    _requestPermission();

    _bluetooth.state.then((state) {
      setState(() => _bluetoothState = state.isEnabled);
    });

    _bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BluetoothState.STATE_OFF:
          setState(() => _bluetoothState = false);
          break;
        case BluetoothState.STATE_ON:
          setState(() => _bluetoothState = true);
          break;
      // case BluetoothState.STATE_TURNING_OFF:
      //   break;
      // case BluetoothState.STATE_TURNING_ON:
      //   break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Devices'),
      ),
      body: Column(
        children: [
          _controlBT(),
          _infoDevice(),
          Expanded(child: _listDevices()),
          _inputSerial(),
          _buttons(),
          Positioned(
            bottom: 16, // Adjust the position as needed
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                // Handle button press
                Navigator.pushNamed(context, '/menu', arguments: orderList);
              },
              child: const Text('Button'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBT() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      tileColor: Colors.black26,
      title: Text(
        _bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado",
      ),
    );
  }

  Widget _infoDevice() {
    return ListTile(
      tileColor: Colors.black12,
      title: Text("Conectado a: ${_deviceConnected?.name ?? "ninguno"}"),
      trailing: _connection?.isConnected ?? false
          ? TextButton(
        onPressed: () async {
          await _connection?.finish();
          setState(() => _deviceConnected = null);
        },
        child: const Text("Desconectar"),
      )
          : TextButton(
        onPressed: _getDevices,
        child: const Text("Ver dispositivos"),
      ),
    );
  }

  Widget _listDevices() {
    return _isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      child: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            ...[
              for (final device in _devices)
                ListTile(
                  title: Text(device.name ?? device.address),
                  trailing: TextButton(
                    child: const Text('conectar'),
                    onPressed: () async {
                      setState(() => _isConnecting = true);

                      final bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
                      //bluetoothManager.connectToDevice(device.address) as BluetoothConnection?;


                      await bluetoothManager.connectToDevice(device.address) as BluetoothConnection?;
                      //_connection = await BluetoothConnection.toAddress(device.address);
                      _deviceConnected = device;
                      _devices = [];
                      _isConnecting = false;

                      _receiveData();

                      setState(() {});
                    },
                  ),
                )
            ]
          ],
        ),
      ),
    );
  }

  Widget _inputSerial() {
    return ListTile(
      trailing: TextButton(
        child: const Text('reiniciar'),
        onPressed: () => setState(() => times = 0),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "Pulsador presionado (x$times)",
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }

  Widget _buttons() {
    final bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
    return Center(
      child: FutureBuilder<Food>(
        future: futureFood,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final mealName = snapshot.data!.strMeal;
            final mealId = snapshot.data!.idMeal;
            final truncatedName = mealName.length > 20
                ? '${mealName.substring(0, 20)}...'
                : mealName;
            return Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () {

                  bluetoothManager.sendData(mealName + '*Orden: ' + mealId);
                  //_sendData(mealName + mealName + '*Orden: ' + mealId);
                },
                child: const Text('My Button'),
              ),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const CircularProgressIndicator();
        },
      ),
    );
    }
}