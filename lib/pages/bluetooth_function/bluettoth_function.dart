import 'package:flutter_blue/flutter_blue.dart';
import './main.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title=""}) : super(key: key);

  final String title;
  // Flutter Blue Instance to access the flutter_blue plug in from library
  final FlutterBlue flutterBlue = FlutterBlue.instance;

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


/**
 * add the connected devices to our list 
 * by accessing the connectedDevices attribute of 
 * our FlutterBlue instance.
 * Note: When start scanning it is required to list only the devices
 * which are not already connected.
 */
  @override
 void initState() {
   super.initState();
   widget.flutterBlue.connectedDevices
       .asStream()
       .listen((List<BluetoothDevice> devices) {
     for (BluetoothDevice device in devices) {
       _addDeviceTolist(device);
     }
   });
   widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
     for (ScanResult result in results) {
       _addDeviceTolist(result.device);
     }
   });
   widget.flutterBlue.startScan();
 }

}
