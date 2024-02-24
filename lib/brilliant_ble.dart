// ignore_for_file: avoid_print

library brilliant_ble;
import 'dart:io';

import 'package:brilliant_ble/brilliant_uuid.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BrilliantBle {
  // connected device
  late BluetoothDevice? _device;
  // List of discovered devices
  final List<BluetoothDevice> _devices = [];

  late BluetoothCharacteristic _replRxCharacteristic;
  late BluetoothCharacteristic _replTxCharacteristic;
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
      await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;
  }
  static Future<BrilliantBle> create() async {
      var component = BrilliantBle._create();
      FlutterBluePlus.setLogLevel(LogLevel.none);
      await component.init();
      return component;
  }
  Future<void> setup({bool autoConnect=true}) async {

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
    },
    onError: (e) => Exception(e));

    await FlutterBluePlus.startScan(
      withServices: List.from([UUID.monocleReplServiceUUID, UUID.monocleDataServiceUUID, UUID.frameServiceUUID, UUID.nordicDfuServiceUUID]),
      timeout: const Duration(seconds:5));

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    FlutterBluePlus.cancelWhenScanComplete(scanSub);
  }
  Future<void> sendData(String data) async {
      if (_device != null  && await _device!.connectionState.first == BluetoothConnectionState.connected){
        await _replRxCharacteristic.write(data.codeUnits);
      }
    }
  Future<void> discoverServices (BluetoothDevice device) async {

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
              print(String.fromCharCodes(value));
              onData!(value);
            });
            device.cancelWhenDisconnected(subscription);
            _replTxCharacteristic.setNotifyValue(true);
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
        // do something with service
    }
  }
  Future<void> connect({BluetoothDevice? device}) async {
    device ??= _device;
    if (device == null) {
      return;
    }
    var subscription = device.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
            print("Disconnected ${device!.disconnectReason}");
            if (onDisconnected != null)
            {
              onDisconnected!();
            }
        }
        if (state == BluetoothConnectionState.connected) {
            print("Connected to ${device!.advName}");
            _device =device;
            await discoverServices(device);
            if (onConnected != null)
            {
              onConnected!();
            }
        }
    });
    device.cancelWhenDisconnected(subscription, delayed:true, next:true);
    await device.connect();
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
  Future<bool> isConnected (){
    return _device!.connectionState.map((event) => event == BluetoothConnectionState.connected).first;
  }
}

