//import 'dart:convert';

import 'package:deru/bluetooth_manager.dart';
import 'package:deru/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPage();
}

class _StartPage extends State<StartPage>{

  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  int times = 0;

  @override
  void initState() {
    super.initState();
    _getDevices();
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

  void _receiveData() {
    _connection?.input?.listen((event) async {

      if (String.fromCharCodes(event) == "c") {
        setState(() => times = times + 1);
        final bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
        final dbHelper = DatabaseHelper();
        bluetoothManager.receiveData(dbHelper);
        print('xrdctvfygh');
      }
    });
  }

  void _getDevices() async {
    print('Drimopiplo');
    var res = await _bluetooth.getBondedDevices();
    setState(() => _devices = res);
  }

  void _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  void _showDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) {
        return SimpleDialog(
          title: const Text('Título del Diálogo'),
          children: [
            SimpleDialogOption(
              child: const Text('Opción 1'),
              onPressed: () {
                debugPrint('Has seleccionado la opción 1');
                //Navigator.of(ctx).pop();
              },
            ),
            SimpleDialogOption(
              child: const Text('Opción 2'),
              onPressed: () {
                debugPrint('Has seleccionado la opción 2');
                //Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _ctrlBT() {
    //final bluetoothManager = Provider.of<BluetoothManager>(context as BuildContext, listen: false);
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      //tileColor: Colors.black26,
      title: Text(
        _bluetoothState ? "Bluetooth" : "Bluetooth",
      ),
    );
  }

  Widget _infoDevice() {
    return ListTile(
      //tileColor: Colors.black12,
      title: const Text("Device"),
      trailing: _connection?.isConnected ?? false
        ? TextButton(
        onPressed: () async {
          await _connection?.finish();
          setState(() => _deviceConnected = null);
        },
        child: const Text("Desconectar"),
      )
      :const Text("Ninguno"),
    );
  }

  Widget _dialog(){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deru'),
      ),
      body: Column(
        children: [
          _ctrlBT(),
          ElevatedButton(
            child: const Text('Connect Device'),
            onPressed: () {
              _getDevices;
              _showDialog(context);

            },
          ),
        ],
      ),
    );
  }

  Widget _listDevices() {
    //_getDevices;
    return _isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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



                    //_connection = await BluetoothConnection.toAddress(device.address);
                    _connection = await bluetoothManager.connectToDevice(device.address);
                    //_connection = await BluetoothConnection.toAddress(device.address);
                    _deviceConnected = device;
                    _devices = [];
                    _isConnecting = false;

                    _receiveData();

                    setState(() {});

                    Navigator.pushNamed(context, '/menu',);
                  },
                ),
              )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deru',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          //centerTitle: true,
          title: const Text('Deru'),
        ),
        body: Column(
          children: [
            _ctrlBT(),
            //_infoDevice(),
            /*ElevatedButton(
              child: const Text('Connect Device'),
              onPressed: () {
                _getDevices;
                print('wsdewyuqgduwdqygwdugqwdyq');
                _infoDevice();
                _listDevices();
                //_showDialog(context);
                Expanded(child: _listDevices());
              },
            ),*/
            _infoDevice(),
            const Divider(),
            Expanded(child: _listDevices()),
          ],
        ),
      ),
    );
  }
}




