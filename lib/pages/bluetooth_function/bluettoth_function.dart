import 'package:flutter_blue/flutter_blue.dart';
import './main.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String title;
  // Flutter Blue Instance to access the flutter_blue plug in from library
  final FlutterBlue flutterBlueInstance = FlutterBlue.instance;

  // Scanning Bluetooth Device
  // Initilaizing a list containing the Devices
  final List<BluetoothDevice> devicesList = [];

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: <Widget>[],
        ),
      );

      /*
      * Helper method to fill the scanning bluetooth device lis
      **/
    _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }
}
