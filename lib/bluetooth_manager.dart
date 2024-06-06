
import 'dart:convert';

import 'package:deru/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothManager extends ChangeNotifier {
  final _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  //bool _bluetoothState = false;
  List<BluetoothDevice> _devices = [];

  int? _currentOrderId;
  int? _itemsLength;
  int _itemsSent = 0;
  List<dynamic> _items = [];

  void receiveData(DatabaseHelper dbHelper) async {
    print('diosito ayudame :C');
    if (_currentOrderId == null) {
      final orders = await dbHelper.getStatus('0');
      if (orders.isNotEmpty) {
        final firstOrder = orders.first;
        _currentOrderId = firstOrder.orderId;
        _items = jsonDecode(firstOrder.items);
        _itemsLength = _items.length;
      }
    }

    if (_itemsLength!= null && _itemsSent < _itemsLength!) {
      final item = _items[_itemsSent];
      sendData('$item*Orden: $_currentOrderId');
      _itemsSent++;
    } else {
      int id = _currentOrderId ?? 0;
      dbHelper.updateOrderStatus(id, '1');
      _currentOrderId = null;
      _itemsLength = null;
      _itemsSent = 0;
      _items = [];
    }
  }




  Future<BluetoothConnection?> connectToDevice(String deviceAddress) async {
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    final device = devices.firstWhere((d) => d.address == deviceAddress);

    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');
      notifyListeners();
      return _connection;
    } catch (error) {
      print('Error connecting to device: $error');

      return null;
    }

  }

  void sendData(String data) {
    if (_connection?.isConnected ?? false) {
      _connection?.output.add(ascii.encode(data));
      notifyListeners();
      print(data);
    }
  }

  void disconnect() {
    _connection?.close();
    _connection = null;
    notifyListeners();
  }

  void _getDevices() async {
    var res = await _bluetooth.getBondedDevices();
    _devices = res;
    notifyListeners();
  }

// Other methods as needed...
}
