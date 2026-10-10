import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;

  // UUIDs from hardware spec
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<List<int>?> receivedData = ValueNotifier(null);

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  /// Scan for available BLE devices
  Future<List<BluetoothDevice>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    final devices = <BluetoothDevice>[];
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devices.any((d) => d.remoteId == result.device.remoteId)) {
          devices.add(result.device);
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    await Future.delayed(timeout);
    await subscription.cancel();

    return devices;
  }

  /// Connect to a specific BLE device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
      isConnected.value = true;

      // Discover services and characteristics
      final services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
              targetCharacteristic = characteristic;
              await _subscribeToCharacteristic();
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      isConnected.value = false;
      debugPrint('Connection error: $e');
      return false;
    }
  }

  /// Subscribe to characteristic notifications
  Future<void> _subscribeToCharacteristic() async {
    if (targetCharacteristic == null) return;

    try {
      await targetCharacteristic!.setNotifyValue(true);
      targetCharacteristic!.onValueReceived.listen((value) {
        receivedData.value = value;
        debugPrint('Received BLE data: $value');
      });
    } catch (e) {
      debugPrint('Subscription error: $e');
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      targetCharacteristic = null;
      isConnected.value = false;
    }
  }

  /// Get connection status
  bool get isDeviceConnected => isConnected.value;
}
