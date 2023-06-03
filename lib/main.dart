import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

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
  Timer? _timer;
  String _windowState = "Нет данных";
  DateTime _timeState = DateTime.now();
  bool _isTimeModeEnabled = false;
  bool _isScheduleEnabled = false;

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      writeHandler?.write(utf8.encode("t;"));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
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
                  await widget.flutterBlue.stopScan();
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

    void readCharacteristic(BluetoothCharacteristic characteristic) async {
      // var value = await characteristic.read();
      // setState(() {
      //   widget.readValues[characteristic.uuid] = value;
      // });
    }

    void initWriteHandler(BluetoothCharacteristic characteristic) {
      writeHandler = characteristic;
    }

    void notificationsSubscribe(BluetoothCharacteristic characteristic) async {
      characteristic.value.listen((value) {
        if (value.isNotEmpty) {
          setState(() {
            widget.readValues[characteristic.uuid] = value;
          });
          var responseMessage = String.fromCharCodes(value);
          if (responseMessage == "o") {
            setState(() {
              _windowState = "Окно открыто";
            });
          } else if (responseMessage == "c") {
            setState(() {
              _windowState = "Окно закрыто";
            });
          } else if (responseMessage.startsWith("t")) {
            final timeBytes = utf8.encode(responseMessage.substring(1));
            final byteData =
                ByteData.sublistView(Uint8List.fromList(timeBytes));
            final seconds = byteData.getInt32(0);
            final minutes = seconds ~/ 60;
            final hours = minutes ~/ 60;
            setState(() {
              _timeState = _timeState.copyWith(
                  hour: hours, minute: minutes % 60, second: seconds % 60);
            });
          } else if (responseMessage == "enable_ok") {
            setState(() {
              _isTimeModeEnabled = true;
            });
          } else if (responseMessage == "disable_ok") {
            setState(() {
              _isTimeModeEnabled = false;
            });
          } else if (responseMessage == "schedule_enabled") {
            setState(() {
              _isScheduleEnabled = true;
            });
          } else if (responseMessage == "schedule_disabled") {
            setState(() {
              _isScheduleEnabled = false;
            });
          }
        }
      });
      await characteristic.setNotifyValue(true);
    }

    if (characteristic.properties.read) {
      readCharacteristic(characteristic);

      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child:
                  const Text('Обновить', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                widget.readValues[characteristic.uuid] =
                    await characteristic.read();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      initWriteHandler(characteristic);

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
      notificationsSubscribe(characteristic);
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
                // characteristic.value.listen((value) {
                //   setState(() {
                //     widget.readValues[characteristic.uuid] = value;
                //   });
                // });
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

    void onTimeSelectButtonTap(BuildContext context) async {
      var timeOfDay = TimeOfDay.fromDateTime(_timeState);
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: timeOfDay,
      );
      if (selectedTime != null &&
          selectedTime != TimeOfDay.fromDateTime(_timeState)) {
        var totalSeconds = selectedTime.hour * 3600 + selectedTime.minute * 60;
        var timeByteList = Uint8List(4)
          ..buffer.asByteData().setInt32(0, totalSeconds, Endian.big);
        var prefix = Uint8List.fromList(utf8.encode('u'));
        var postfix = Uint8List.fromList(utf8.encode(';'));
        await writeHandler?.write([...prefix, ...timeByteList, ...postfix]);
      }
    }

    void onTimeModeButtonTap(BuildContext context) async {
      final selectedActiveTime = await showTimePicker(
          context: context,
          helpText: "Время в открытом положении",
          initialTime: TimeOfDay.fromDateTime(DateTime.now()));

      final selectedDelayTime = await showTimePicker(
          context: context,
          helpText: "Время в закрытом положении",
          initialTime: TimeOfDay.fromDateTime(DateTime.now()));

      if (selectedActiveTime != null && selectedDelayTime != null) {
        var activeTimeSeconds =
            selectedActiveTime.hour * 3600 + selectedActiveTime.minute * 60;
        var delayTimeSeconds =
            selectedDelayTime.hour * 3600 + selectedDelayTime.minute * 60;
        var activeTimeBytes = Uint8List(4)
          ..buffer.asByteData().setInt32(0, activeTimeSeconds, Endian.big);
        var delayTimeBytes = Uint8List(4)
          ..buffer.asByteData().setInt32(0, delayTimeSeconds, Endian.big);
        var prefix = Uint8List.fromList(utf8.encode('r'));
        var postfix = Uint8List.fromList(utf8.encode(';'));
        await writeHandler?.write(
            [...prefix, ...activeTimeBytes, ...delayTimeBytes, ...postfix]);
      }
    }

    void onTimeModeCheckboxChange(bool? _) async {
      if (_isTimeModeEnabled) {
        await writeHandler?.write(utf8.encode('d'));
      } else {
        await writeHandler?.write(utf8.encode('e'));
      }
    }

    void onScheduleCheckboxChange(bool? _) async {
      if (_isScheduleEnabled) {
        await writeHandler?.write(utf8.encode('disable_schedule'));
      } else {
        await writeHandler?.write(utf8.encode('enable_schedule'));
      }
    }

    void onSetScheduleButtonTap(BuildContext context) async {
      final selectedOpenTime = await showTimePicker(
          context: context,
          helpText: "Время открытия",
          initialTime: TimeOfDay.fromDateTime(DateTime.now()));

      if (selectedOpenTime != null) {
        final selectedCloseTime = await showTimePicker(
            context: context,
            helpText: "Время закрытия",
            initialTime: TimeOfDay.fromDateTime(DateTime.now()));

        if (selectedCloseTime != null) {
          var openTimeSeconds =
              selectedOpenTime.hour * 3600 + selectedOpenTime.minute * 60;
          var closeTimeSeconds =
              selectedCloseTime.hour * 3600 + selectedCloseTime.minute * 60;
          var activeTimeBytes = Uint8List(4)
            ..buffer.asByteData().setInt32(0, openTimeSeconds, Endian.big);
          var delayTimeBytes = Uint8List(4)
            ..buffer.asByteData().setInt32(0, closeTimeSeconds, Endian.big);
          var prefix = Uint8List.fromList(utf8.encode('h'));
          var postfix = Uint8List.fromList(utf8.encode(';'));
          await writeHandler?.write(
              [...prefix, ...activeTimeBytes, ...delayTimeBytes, ...postfix]);
        }
      }
    }

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
                          '${String.fromCharCodes(widget.readValues[characteristic.uuid] ?? [])}${widget.readValues[characteristic.uuid] ?? []}')
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

    // containers.add(Padding(
    //     padding: const EdgeInsets.symmetric(horizontal: 15),
    //     child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
    //       Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    //         const Text('Часы'),
    //         NumberPicker(
    //             minValue: 0,
    //             maxValue: 24,
    //             value: 0,
    //             axis: Axis.vertical,
    //             onChanged: (_) {}),
    //       ]),
    //       Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    //         const Text('Минуты'),
    //         NumberPicker(
    //             minValue: 0,
    //             maxValue: 60,
    //             value: 0,
    //             axis: Axis.vertical,
    //             onChanged: (_) {})
    //       ])
    //     ])));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          ElevatedButton(
              onPressed: () {
                writeHandler?.write(utf8.encode("o;"));
              },
              child: const Text("Открыть окно")),
          ElevatedButton(
              onPressed: () {
                writeHandler?.write(utf8.encode("c;"));
              },
              child: const Text("Закрыть окно"))
        ]),
        Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Text("Состояние: $_windowState",
                  style: const TextStyle(color: Colors.black, fontSize: 16)),
              Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ElevatedButton(
                      onPressed: () async {
                        await writeHandler?.write(utf8.encode("s;"));
                      },
                      child: const Text("Обновить")))
            ])),
        Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Text("Время: ${DateFormat("HH:mm:ss").format(_timeState)}",
                  style: const TextStyle(color: Colors.black, fontSize: 16)),
              Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: ElevatedButton(
                      onPressed: () async {
                        await writeHandler?.write(utf8.encode("t;"));
                      },
                      child: const Text("Обновить")))
            ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => onTimeSelectButtonTap(context),
            child: const Text('Изменить время'),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => onTimeModeButtonTap(context),
            child: const Text('Установить режим работы'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            const Text(
              'Работать по режиму',
            ),
            Checkbox(
                onChanged: onTimeModeCheckboxChange, value: _isTimeModeEnabled),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => onSetScheduleButtonTap(context),
            child: const Text('Установить расписание'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            const Text(
              'Работать по расписанию',
            ),
            Checkbox(
                onChanged: onScheduleCheckboxChange, value: _isScheduleEnabled),
          ]),
        )
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
