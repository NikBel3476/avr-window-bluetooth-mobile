import 'dart:io';

import 'package:avr_bluetooth/widgets/available_device_list.dart';
import 'package:avr_bluetooth/widgets/connected_device_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const MyApp());
    });
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AVR window',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'AVR window'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    widget.flutterBlue.startScan();
  }

  @override
  void dispose() {
    super.dispose();
    widget.flutterBlue.stopScan();
  }

  void onDeviceConnectButtonTap(
      BuildContext context, BluetoothDevice device) async {
    widget.flutterBlue.stopScan();
    try {
      await device.connect();
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return ConnectedDeviceView(device: device);
    }));
  }

  Widget _buildView() => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AvailableDeviceList(
          deviceList: widget.devicesList,
          onDeviceConnectButtonTap: onDeviceConnectButtonTap));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}
