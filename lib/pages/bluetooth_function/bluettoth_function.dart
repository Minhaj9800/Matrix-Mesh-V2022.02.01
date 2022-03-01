import 'package:flutter_blue/flutter_blue.dart';
import './main.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title = ""}) : super(key: key);

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
        body: _buildListViewOfDevices(),
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

  /// Building ListView with the deviceList as Content.
  ListView _buildListViewOfDevices() {
    List<Container> containers = [];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              FlatButton(
                color: Colors.blue,
                child: Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  // ListView _buildView() {
  //   if (_connectedDevice != null) {
  //     return _buildConnectDeviceView();
  //   }
  //   return _buildListViewOfDevices();
  // }

  /**
   * Assign the list view as the body of main scaffold
   */
  // @override
  // Widget build(BuildContext context) => Scaffold(
  //       appBar: AppBar(
  //         title: Text(widget.title),
  //       ),
  //       body: _buildListViewOfDevices(),
  //     );
}
