import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../utils/snackbar.dart';
import 'connected_device_view.dart';

class AvailableDeviceList extends StatefulWidget {
  const AvailableDeviceList({super.key});

  @override
  State<AvailableDeviceList> createState() => _AvailableDeviceListState();
}

class _AvailableDeviceListState extends State<AvailableDeviceList> {
  List<BluetoothDevice> deviceList = [];
  late Stream<List<ScanResult>> _scanResults;

  @override
  void initState() {
    super.initState();
    startScan();

    _scanResults = FlutterBluePlus.scanResults;
  }

  @override
  void dispose() {
    if (FlutterBluePlus.isScanningNow) FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future startScan() async {
    try {
      await FlutterBluePlus.startScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start scan error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void onDeviceConnectButtonTap(BluetoothDevice device) async {
    try {
      if (FlutterBluePlus.isScanningNow) await FlutterBluePlus.stopScan();
      await device.connect();
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ConnectedDeviceView(device: device)));
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ScanResult>>(
      stream: _scanResults,
      initialData: const [],
      builder: (c, snapshot) => ListView(
          children: snapshot.data!
              .map((result) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text(result.device.platformName == ''
                                  ? '(неизвестное устройство)'
                                  : result.device.platformName),
                              Text(result.device.remoteId.toString()),
                            ],
                          ),
                        ),
                        TextButton(
                            onPressed: result.advertisementData.connectable
                                ? () =>
                                    onDeviceConnectButtonTap.call(result.device)
                                : null,
                            child: const Text(
                              'Подключиться',
                              style: TextStyle(color: Colors.blue),
                            )),
                      ],
                    ),
                  ))
              .toList()));
}
