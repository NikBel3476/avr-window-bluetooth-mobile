import 'dart:async';

import 'package:avr_bluetooth/screens/bluetooth_off_screen.dart';
import 'package:avr_bluetooth/widgets/available_device_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(const AvrWindowApp());
}

class AvrWindowApp extends StatelessWidget {
  const AvrWindowApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'AVR window',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MainPage(title: 'AVR window'),
      );
}

class MainPage extends StatefulWidget {
  MainPage({Key? key, required this.title}) : super(key: key);

  final String title;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  Widget _buildView() => const Padding(
      padding: EdgeInsets.only(top: 8), child: AvailableDeviceList());

  @override
  Widget build(BuildContext context) =>
      _adapterState == BluetoothAdapterState.on
          ? Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: _buildView(),
            )
          : BluetoothOffScreen(adapterState: _adapterState);
}
