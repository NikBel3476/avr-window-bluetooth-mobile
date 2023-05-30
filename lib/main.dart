import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(const MyApp());

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
  final _writeController = TextEditingController();
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  BluetoothCharacteristic? writeHandler;
  BluetoothCharacteristic? readHandler;
  String windowState = "Нет данных";
  DateTime timeState = DateTime.now();

  _addDeviceToList(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceToList(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceToList(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Widget> containers = <Widget>[];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        SizedBox(
          height: 50,
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
                onPressed: () async {
                  widget.flutterBlue.stopScan();
                  try {
                    await device.connect();
                  } on PlatformException catch (e) {
                    if (e.code != 'already_connected') {
                      rethrow;
                    }
                  } finally {
                    _services = await device.discoverServices();
                  }
                  setState(() {
                    _connectedDevice = device;
                  });
                },
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

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child:
                  const Text('Прочитать', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      writeHandler = characteristic;

      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('Отправить',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Отправить"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("Отправить"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            child: const Text("Закрыть"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      characteristic.value.listen((value) {
        setState(() {
          var responseMessage = String.fromCharCodes(value).toLowerCase();
          if (responseMessage == "o") {
            windowState = "Окно открыто";
          } else if (responseMessage == "c") {
            windowState = "Окно закрыто";
          } else if (responseMessage.startsWith("t")) {
            final timeBytes = utf8.encode(responseMessage.substring(1));
            final byteData =
                ByteData.sublistView(Uint8List.fromList(timeBytes));
            final seconds = byteData.getInt32(0);
            final minutes = seconds ~/ 60;
            final hours = minutes ~/ 60;
            timeState = timeState.copyWith(
                hour: hours, minute: minutes % 60, second: seconds % 60);
          }
        });
      });
      characteristic.setNotifyValue(true);

      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('Получение данных',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Widget> containers = <Widget>[];

    for (BluetoothService service in _services) {
      List<Widget> characteristicsWidget = <Widget>[];

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.read ||
            characteristic.properties.notify) {
          characteristicsWidget.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(characteristic.uuid.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      ..._buildReadWriteNotifyButton(characteristic),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                          'Значение: ${String.fromCharCodes(widget.readValues[characteristic.uuid] ?? [])}'),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
          );
        }
      }
      if (characteristicsWidget.isNotEmpty) {
        containers.add(
          ExpansionTile(
              title: Text(service.uuid.toString()),
              children: characteristicsWidget),
        );
      }
    }

    containers
        .add(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      ElevatedButton(
          onPressed: () {
            writeHandler?.write(utf8.encode("o"));
          },
          child: const Text("Открыть окно")),
      ElevatedButton(
          onPressed: () {
            writeHandler?.write(utf8.encode("c"));
          },
          child: const Text("Закрыть окно"))
    ]));

    containers.add(Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text("Состояние: $windowState",
              style: const TextStyle(color: Colors.black, fontSize: 16)),
          Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton(
                  onPressed: () async {
                    await writeHandler?.write(utf8.encode("s"));
                  },
                  child: const Text("Обновить")))
        ])));

    containers.add(Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text(
              "Время: ${timeState.hour}:${timeState.minute}:${timeState.second}",
              style: const TextStyle(color: Colors.black, fontSize: 16)),
          Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton(
                  onPressed: () async {
                    await writeHandler?.write(utf8.encode("t"));
                  },
                  child: const Text("Обновить")))
        ])));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}
