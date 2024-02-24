library brilliant_uuid;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
/* 
  This is a simple library that wraps the Guid class from the flutter_blue_plus package.
  It is used to convert a string to a Guid object.
  This is useful when working with the flutter_blue_plus package, as it requires a Guid object to be passed to it.
*/
class UUID {
static var monocleReplServiceUUID =   Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
static var monocleDataServiceUUID = Guid('e5700001-7bac-429a-b4ce-57ff900f479d');
static var frameServiceUUID = Guid('7A230001-5475-A6A4-654C-8431F6AD49C4');

static var nordicDfuServiceUUID = Guid('fe59');

static var monocleReplRxCharacteristicUUID = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
static var monocleReplTxCharacteristicUUID = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

static var monocleRawDataRxCharacteristicUUID = Guid('e5700002-7bac-429a-b4ce-57ff900f479d');
static var monocleRawDataTxCharacteristicUUID = Guid('e5700003-7bac-429a-b4ce-57ff900f479d');

static var nordicDfuControlCharacteristicUUID = Guid('8ec90001-f315-4f60-9fb8-838830daea50');
static var nordicDfuPacketCharacteristicUUID = Guid('8ec90002-f315-4f60-9fb8-838830daea50');

static var frameTxCharacteristicUUID = Guid('7A230002-5475-A6A4-654C-8431F6AD49C4');
static var frameRxCharacteristicUUID = Guid('7A230003-5475-A6A4-654C-8431F6AD49C4');
}



