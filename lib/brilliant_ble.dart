// ignore_for_file: avoid_print

library brilliant_ble;

import 'dart:async';
import 'dart:io';

import 'package:brilliant_ble/brilliant_uuid.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BrilliantBle {
  // connected device
  late BluetoothDevice? _device;
  // List of discovered devices
  final List<BluetoothDevice> _devices = [];

  late BluetoothCharacteristic? _replRxCharacteristic;
  late BluetoothCharacteristic? _replTxCharacteristic;
  late BluetoothCharacteristic? _frameRxCharacteristic;
  late BluetoothCharacteristic? _frameTxCharacteristic;
  late int _mtu = 100;
  late Function _responseCallback;
  late Completer<String?> _completer; 
  // late BluetoothCharacteristic _monocleRawDataRxCharacteristic;
  // late BluetoothCharacteristic _monocleRawDataTxCharacteristic;
  Function? onData;
  Function? onConnected;
  Function? onDisconnected;
  BrilliantBle._create() {
    print("starting");
  }
  Future<void> init() async {
    if (await FlutterBluePlus.isSupported == false) {
      Exception("Bluetooth not supported");
      return;
    }
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;
  }

  static Future<BrilliantBle> create() async {
    var component = BrilliantBle._create();
    FlutterBluePlus.setLogLevel(LogLevel.none);
    await component.init();
    return component;
  }

  Future<BluetoothDevice?> setup({bool autoConnect = true}) async {
    // disconnect all devices
    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
      for (var device in FlutterBluePlus.connectedDevices) {
        await device.disconnect();
      }
    }
    await scan();
    if (_devices.isNotEmpty && autoConnect) {
      await connect(
        device: _devices.first,
      );
    }
    return _device;
  }

  Future<void> scan() async {
    var scanSub = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        for (var result in results) {
          if (!_devices.contains(result.device)) {
            _devices.add(result.device);
          }
        }
      }
    }, onError: (e) => Exception(e));

    await FlutterBluePlus.startScan(
        withServices: List.from([
          UUID.monocleReplServiceUUID,
          UUID.monocleDataServiceUUID,
          UUID.frameServiceUUID,
          UUID.nordicDfuServiceUUID
        ]),
        timeout: const Duration(seconds: 5));

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    FlutterBluePlus.cancelWhenScanComplete(scanSub);
  }

  //  Send data of any length to frame or monocle service
  Future<String?> sendData(String data, {wait = true}) async {
    if (_device != null &&
        await _device!.connectionState.first ==
            BluetoothConnectionState.connected) {
      var bits = data.codeUnits;
       _completer = Completer();
    // send in chunks of _mtu - 3  bytes
      for (var i = 0; i < bits.length; i += _mtu - 3) {
        var end = i + _mtu - 3;
        if (end > bits.length) {
          end = bits.length;
        }
        await _sendDataChunk(bits.sublist(i, end));
      }
    }
    _responseCallback = (data) {
      _completer.complete(data);
    };
    Timer(const Duration(seconds: 5), () {
      if (!_completer.isCompleted) _completer.complete(null);
    });
    return wait?_completer.future:null;
  }
  Future<void> _sendDataChunk(List<int> bits ) async {

      if (_frameRxCharacteristic != null) {
        await _frameRxCharacteristic!.write(bits);
      } else if (_replRxCharacteristic != null) {
        await _replRxCharacteristic!.write(bits);
      }
  }
  Future<void> uploadFile(String path, String data) async {
    if (_device != null &&
        await _device!.connectionState.first ==
            BluetoothConnectionState.connected) {
      if (device!.advName.toLowerCase().contains("monocle")) {
        // TODO implement file upload for monocle
      }
      if (device!.advName.toLowerCase().contains("frame")) {
         
            // if drectory remove trailing / and create directory
            if (path.contains("/")){
              var dirpath = path.substring(0,path.lastIndexOf("/"));
            var dirMakeCmd = "a=frame.file.mkdir('$dirpath');print(a);";
              await sendData(dirMakeCmd);
            }
            if (data.isEmpty){
              await sendData("f = frame.file.open('$path', 'w');f:write('');print(f:close());");
            }else{
              // create file and write data in mtu chunks
              await sendData("f = frame.file.open('$path', 'w');print(f);");
              var chunkSize = _mtu-40;
              for (var i = 0; i < data.length; i += chunkSize) {
                var chunk = data.substring(i, i + chunkSize);
                await sendData("f:write([[$chunk]]);");
              }
              await sendData("print(f:close());");
            }
      }
    }
  }
  Future<List<String>> listFiles(String path) async {
    if (_device != null &&
        await _device!.connectionState.first ==
            BluetoothConnectionState.connected) {

      if (device!.advName.toLowerCase().contains("monocle")) {
        // TODO implement file upload for monocle
      }
      if (device!.advName.toLowerCase().contains("frame")) {
        var cmd = "a=frame.file.listdir('$path');print(a);";
        await sendData(cmd);
      }
    }
    return [];
  }
  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid == UUID.monocleReplServiceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == UUID.monocleReplRxCharacteristicUUID) {
            _replRxCharacteristic = characteristic;
          }
          if (characteristic.uuid == UUID.monocleReplTxCharacteristicUUID) {
            _replTxCharacteristic = characteristic;
            final subscription = characteristic.onValueReceived.listen((value) {
                _responseCallback(String.fromCharCodes(value));
              if (onData != null) {
                onData!(value);
              }
              
            });
            device.cancelWhenDisconnected(subscription);
            _replTxCharacteristic!.setNotifyValue(true);
          }
        }
      }
      if (service.uuid == UUID.monocleDataServiceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == UUID.monocleRawDataRxCharacteristicUUID) {
            // _monocleRawDataRxCharacteristic = characteristic;
          }
          if (characteristic.uuid == UUID.monocleRawDataTxCharacteristicUUID) {
            // _monocleRawDataTxCharacteristic = characteristic;
          }
        }
      }
      if (service.uuid == UUID.frameServiceUUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == UUID.frameRxCharacteristicUUID) {
            // _monocleRawDataRxCharacteristic = characteristic;
          }
          if (characteristic.uuid == UUID.frameTxCharacteristicUUID) {
            _frameTxCharacteristic = characteristic;
            final subscription = characteristic.onValueReceived.listen((value) {
                _responseCallback(String.fromCharCodes(value));
              if (onData != null) {
                onData!(value);
              }
            });
            device.cancelWhenDisconnected(subscription);
            _frameTxCharacteristic!.setNotifyValue(true);
          }
          if (characteristic.uuid == UUID.frameRxCharacteristicUUID) {
            _frameRxCharacteristic = characteristic;
          }
        }
      }
      // do something with service
    }
  }

  Future<BluetoothDevice?> connect({BluetoothDevice? device}) async {
    device ??= _device;
    if (device == null) {
      return null;
    }
    var subscription = device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        if (onDisconnected != null) {
          onDisconnected!();
        }
      }
      if (state == BluetoothConnectionState.connected) {
        var mtuSubscription = device!.mtu.listen((int mtu) {
          _mtu = mtu;
        });
        device.cancelWhenDisconnected(mtuSubscription);
        _device = device;
        await discoverServices(device);
        if (onConnected != null) {
          onConnected!();
        }
      }
    });
    
    device.cancelWhenDisconnected(subscription, delayed: true, next: true);
    await device.connect();
    return device;
    // await device.disconnect();
  }

  Future<void> disconnect() async {
    if (_device != null) {
      await _device!.disconnect();
    }
  }

  Future<void> dispose() async {
    await disconnect();
  }

  BluetoothDevice? get device => _device;
  List<BluetoothDevice> get devices => _devices;
  Future<bool> isConnected() {
    return _device!.connectionState
        .map((event) => event == BluetoothConnectionState.connected)
        .first;
  }
}
