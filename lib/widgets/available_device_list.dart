import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AvailableDeviceList extends StatelessWidget {
  const AvailableDeviceList(
      {super.key, required this.deviceList, this.onDeviceConnectButtonTap});

  final List<BluetoothDevice> deviceList;
  final Function(BluetoothDevice)? onDeviceConnectButtonTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: deviceList.length,
        itemBuilder: (context, i) {
          var device = deviceList[i];
          return Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(device.name == ''
                          ? '(неизвестное устройство)'
                          : device.name),
                      Text(device.id.toString()),
                    ],
                  ),
                ),
                TextButton(
                    child: const Text(
                      'Подключиться',
                      style: TextStyle(color: Colors.blue),
                    ),
                    onPressed: () => onDeviceConnectButtonTap?.call(device)),
              ],
            ),
          );
        });
  }
}
