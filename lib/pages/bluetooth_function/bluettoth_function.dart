import 'package:flutter_blue/flutter_blue.dart';
import './main.dart';
import 'package:flutter/material.dart';
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String title;
  // Flutter Blue Instance to access the flutter_blue plug in from library
  final FlutterBlue flutterBlueInstance  = FlutterBlue.instance;

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
}