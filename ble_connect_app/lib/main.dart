import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:device_info/device_info.dart';

import 'device_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.cyan,
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.cyan,
          textTheme: ButtonTextTheme.primary,
        ),
        useMaterial3: true,
      ),
      home: const DeviceSelectionScreen(),
    );
  }
}


class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  _DeviceSelectionScreenState createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  late StreamSubscription<List<ScanResult>> scanResultSubscription;
  late StreamSubscription<BluetoothDeviceState> bluetoothDeviceStateSubscription;
  String identifier = 'Loading identifier...';

  Future<String> getDeviceIdentifier() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.androidId;
  }

  @override
  void initState() {
    super.initState();
    getDeviceIdentifier().then((value) {
      setState(() {
        identifier = value;
      });
    });
  }

  void startScan() {
    disconnectAllDevices();
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    // Subscribe to the scan results and update the list
    scanResultSubscription = flutterBlue.scanResults.listen((List<ScanResult> results) {
      setState(() {
        scanResults = results;
      });
    });

    setState(() {
      isScanning = true;
    });
  }

  void stopScan() {
    flutterBlue.stopScan();
    setState(() {
      isScanning = false;
    });
  }

  void disconnectAllDevices() async {
    // Scan for connected devices
    List<BluetoothDevice> connectedDevices = await flutterBlue.connectedDevices;

    // Disconnect each connected device
    for (BluetoothDevice device in connectedDevices) {
      await device.disconnect();
    }
  }

  void connectToDevice(BluetoothDevice device, context) {
    device.connect();

    bluetoothDeviceStateSubscription = device.state.listen((state) async {
      if (state == BluetoothDeviceState.connected) {
        print('Connected to ${device.name}');
        await scanResultSubscription.cancel();
        await bluetoothDeviceStateSubscription.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyCustomWidget(device: device)),
        );

        // Perform your required actions with the connection here
        // Example: send/receive data, read/write characteristics, etc.

        // Disconnect the device when it's no longer needed
        // await device.disconnect();
      } else if (state == BluetoothDeviceState.disconnected) {
        print('Failed to connect to ${device.name}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<ScanResult> filteredScanResults = scanResults.where((scanResult) {
      List<String> services = scanResult.advertisementData.serviceUuids;
      for (String service in services) {
        if (service == "00000002-0000-1000-8000-00805f9b34fb") {
          return true; // The device offers the desired service
        }
      }
      return false; // The device does not offer the desired service
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Selection'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? stopScan : startScan,
            child: Text(isScanning ? 'Stop Scan' : 'Start Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredScanResults.length,
              itemBuilder: (context, index) {
                ScanResult scanResult = filteredScanResults[index];
                BluetoothDevice device = scanResult.device;
                bool isDeviceLocked = device.name == 'Automatic Guest Verifier'; // Assuming 'Automatic Guest Verifier' is the name of the locked device
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id.toString()),
                  leading: isDeviceLocked ? Icon(Icons.lock) : null,
                  onTap: () {
                    connectToDevice(device, context);
                  },
                );
              },
            )
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: identifier));
              final snackBar = SnackBar(
                content: Text(
                  'Identifier copied to clipboard',
                  textAlign: TextAlign.center,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Copy Personal Identifier',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.content_copy),
              ],
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }
}
