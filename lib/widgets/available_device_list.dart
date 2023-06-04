import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AvailableDeviceList extends StatelessWidget {
  const AvailableDeviceList(
      {super.key, required this.deviceList, this.onDeviceConnectButtonTap});

  final List<BluetoothDevice> deviceList;
  final Function(BuildContext, BluetoothDevice)? onDeviceConnectButtonTap;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ScanResult>>(
      stream: FlutterBluePlus.instance.scanResults,
      initialData: const [],
      builder: (c, snapshot) => Column(
          children: snapshot.data!
              .map((result) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Text(result.device.name == ''
                                  ? '(неизвестное устройство)'
                                  : result.device.name),
                              Text(result.device.id.toString()),
                            ],
                          ),
                        ),
                        TextButton(
                            onPressed: result.advertisementData.connectable
                                ? () => onDeviceConnectButtonTap?.call(
                                    context, result.device)
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
