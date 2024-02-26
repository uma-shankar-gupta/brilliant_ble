# [BrilliantBle](https://pub.dev/packages/brilliant_ble)
 A Flutter package to connect to BLE devices by [brilliant Labs](https://brilliant.xyz)\
 It Uses [FlutterBluePlus](https://pub.dev/packages/flutter_blue_plus) as a dependency to connect to BLE devices.

Provide an abstraction layer over the FlutterBluePlus package to make it easier to connect to BLE devices and to read write files and data to devices.

## Features

1. Connect to BLE devices (Brilliant Labs devices only for now)\
   a. Monocle (Supported)\
   b. Frame (TODO)
2. Read and write data to BLE devices
3. Read and write files to BLE devices

## Getting started

Install the package by adding the following to your `pubspec.yaml` file:

```yaml
dependencies:
  brilliant_ble: ^0.0.3
```
or with flutter pub
```bash
flutter pub add brilliant_ble
```

Then run `flutter pub get` to install the package.
## For Android
flutter_blue_plus is compatible only from version 21 of Android SDK so you should change this in your `android/app/build.gradle` file\
__android/app/build.gradle:__
```gradle
android {
  defaultConfig {
     minSdkVersion: 21
```
Add the following permissions to your `AndroidManifest.xml` file\
__android/app/src/main/AndroidManifest.xml:__
```xml
<!-- Tell Google Play Store that your app uses Bluetooth LE
     Set android:required="true" if bluetooth is necessary -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="false" />

<!-- New Bluetooth permissions in Android 12
https://developer.android.com/about/versions/12/features/bluetooth-permissions -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- legacy for Android 11 or lower -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30"/>

<!-- legacy for Android 9 or lower -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="28" />
```
## For iOS
Add the following permissions to your `Info.plist` file
```xml
<dict>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>This app always needs Bluetooth to function</string>
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>This app needs Bluetooth Peripheral to function</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app always needs location and when in use to function</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>This app always needs location to function</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location when in use to function</string>
    <key>UIBackgroundModes</key>
    <array>
        <string>bluetooth-central</string>
    </array>
```

## Usage


```dart
ble = await BrilliantBle.create();
ble.onConnected = () {
   print("connected");
};
ble.onDisconnected = () {
 print("Disconnected");

};
ble.onData = (data) {
// Data Recieved from the device
print(String.fromCharCodes(data));
};
await ble.setup();

```
Then after connecting to the device you can send and receive data using the following methods
```dart
  //send data to the device with waiting for response
  var response = await ble.sendData("print('hello world')\n\r");
  print(response); // output: hello world
  //send data to the device without waiting for response
  await ble.sendData("print('hello world')\n\r", wait: false);

  //send upload file to the device
  await ble.uploadFile("file.txt", "file content");
```
Check connection status
```dart
  var status = await ble.isConnected();
  print(status); // output: true or false
```
Disconnect from the device
```dart
  await ble.disconnect();
```
Check name of the connected device
```dart
  var name = await ble.device.advName();
  print(name); // output: monocle/frame
```
If want to manually scan and connect to the device
```dart
  await ble.scan();
  var devices = ble.devices;
  for (var d in devices) {
    print(d.advName);
  }

  // connect to first device
  var device = await ble.connect(device[0]);
```
## TODO
- [x] Add support for Monocle REPL (Done)
- [ ] Add support for Monocle File System 
- [ ] Add support for Monocle Data service
- [ ] Add support for Monocle Device Firmware Update
- [x] Add support for Frame (Done)
- [ ] Add support for Frame File System (WIP)
- [ ] Add support for Frame Device Firmware Update



