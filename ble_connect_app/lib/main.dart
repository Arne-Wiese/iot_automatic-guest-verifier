import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';
import 'package:device_info/device_info.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  String identifier = 'Lade identifier...';

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

    // Abonnieren Sie die Scan-Results und aktualisieren Sie die Liste
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
    // Scanne nach verbundenen Geräten
    List<BluetoothDevice> connectedDevices = await flutterBlue.connectedDevices;
    print(connectedDevices);

    // Trenne jedes verbundene Gerät
    for (BluetoothDevice device in connectedDevices) {
      await device.disconnect();
    }
  }



  void connectToDevice(BluetoothDevice device, context) {
    device.connect();

    bluetoothDeviceStateSubscription = device.state.listen((state) async {
      if (state == BluetoothDeviceState.connected) {
        print('Verbindung hergestellt mit ${device.name}');
        await scanResultSubscription.cancel();
        await bluetoothDeviceStateSubscription.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MyCustomWidget( device: device)),
        );


        // Führen Sie hier Ihre erforderlichen Aktionen mit der Verbindung durch
        // Beispiel: Daten senden/empfangen, Charakteristiken lesen/schreiben, usw.

        // Trennen Sie die Verbindung, wenn sie nicht mehr benötigt wird
        // await device.disconnect();

      } else if (state == BluetoothDeviceState.disconnected) {
        print('Fehler beim Verbinden mit ${device.name}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<ScanResult> filteredScanResults = scanResults.where((scanResult) {
      List<String> services = scanResult.advertisementData.serviceUuids;
      for (String service in services) {
        if (service == "00000002-0000-1000-8000-00805f9b34fb") {
          return true; // Das Gerät bietet den gewünschten Service an
        }
      }
      return false; // Das Gerät bietet den gewünschten Service nicht an
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
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id.toString()),
                  onTap: () {
                    connectToDevice(device, context);
                  },
                );
              },
            ),
          ),
          GestureDetector(
          onTap: () {
          Clipboard.setData(ClipboardData(text: identifier));
          final snackBar = SnackBar(content: Text('Identifier in die Zwischenablage kopiert', textAlign: TextAlign.center,));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
          child:
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(
            'Persönlichen Identifier kopieren',
            style: TextStyle(fontSize: 16),
          ),
            SizedBox(width: 8), // Abstand zwischen Text und Icon
            Icon(Icons.content_copy), // Kopier-Icon
          ]),
    ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }




}


