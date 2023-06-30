import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';


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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  _DeviceSelectionScreenState createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResults = [];
  bool isScanning = false;



  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    // Abonnieren Sie die Scan-Results und aktualisieren Sie die Liste
    flutterBlue.scanResults.listen((List<ScanResult> results) {
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



  void connectToDevice(BluetoothDevice device, context) {
    StreamSubscription<BluetoothDeviceState> subscription;
      device.connect();

      subscription = device.state.listen((state) async {
        if (state == BluetoothDeviceState.connected) {
          print('Verbindung hergestellt mit ${device.name}');

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
    print('started');
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
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                ScanResult scanResult = scanResults[index];
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
        ],
      ),
    );
  }
}

class MyCustomWidget extends StatefulWidget {
  final BluetoothDevice device;

  const MyCustomWidget({super.key, required this.device});
  @override
  _MyCustomWidgetState createState() => _MyCustomWidgetState();
}

class _MyCustomWidgetState extends State<MyCustomWidget> {
  late BluetoothCharacteristic characteristic;
  late StreamSubscription<List<int>> subscription;
  String access = 'Warte auf Antwort...';

  @override
  Widget build(BuildContext context) {
    BluetoothDevice device = widget.device;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Connected to:'),
            Text('Name: ${device.name}'),
            Text('Adresse: ${device.id.toString()}'),
            const SizedBox(height: 16),
            Text(access),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    sendDataToDoor(device);
                  },
                  child: const Text('Get Access'),

                ),
                ElevatedButton(
                  onPressed: () {
                    try {
                      subscription.cancel();
                    }catch(e){
                      // Hhh
                    }
                    device.disconnect();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
                    );
                  },
                  child: const Text('Disconnect'),

                ),
              ],
            )
          ],
        ),
      ),
    );
  }



  void sendDataToDoor(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    // Suchen Sie die gewünschte Charakteristik in den gefundenen Diensten
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == "00000002-0000-1000-8000-00805f9b34fb") {
          characteristic = c;
        }
      }

    }
    String request = "Hello, world!"; // Der UTF-8-Request, den du senden möchtest
    List<int> data = utf8.encode(request); // UTF-8-Request in Bytes umwandeln
    await characteristic.setNotifyValue(true);
    subscription = characteristic.value.listen((value) {
      String response = utf8.decode(value);
      setState(() {
        access = response;
      });
      print("Antwort erhalten: $response");
      // Hier kannst du die empfangenen Daten weiterverarbeiten
    });
    await characteristic.write(data);

  }

}