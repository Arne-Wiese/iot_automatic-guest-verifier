import 'dart:async';
import 'dart:convert';

import 'package:ble_example/admin_screen.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'main.dart';
import 'overlay_dialog.dart';

class MyCustomWidget extends StatefulWidget {
  final BluetoothDevice device;

  const MyCustomWidget({super.key, required this.device});
  @override
  _MyCustomWidgetState createState() => _MyCustomWidgetState();
}

class _MyCustomWidgetState extends State<MyCustomWidget> {
  late BluetoothCharacteristic guestAccessCharacteristic;
  late BluetoothCharacteristic adminAuthenticationCharacteristic;
  late StreamSubscription<List<int>> guestAccessSubscription;
  late StreamSubscription<List<int>> adminAuthenticationSubscription;

  bool isGuestAccessSubscriptionSet = false;
  bool isAdminAuthenticationSubscriptionSet = false;
  String access = 'Warte auf Antwort...';
  bool authErrorIsVisible = false;

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
                    handleDisconnect(device);
                  },
                  child: const Text('Disconnect'),

                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                authenticate(device);

              },
              child: const Text('Als Admin authentifizieren'),
            ),
            const SizedBox(height: 32),
            Visibility(
            visible: authErrorIsVisible,
            child: Text(
            'Falsches Passwort!',
            style: TextStyle(color: Colors.red),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> authenticate(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    // Suchen Sie die gewünschte Charakteristik in den gefundenen Diensten
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == "00000004-0000-1000-8000-00805f9b34fb") {
          adminAuthenticationCharacteristic = c;
        }
      }
    }
    String? userInput = await showDialog<String>(
      context: context,
      builder: (context) => OverlayDialog( text: 'Passwort:',),
    );

    if(userInput != null && userInput != ""){
      String password = userInput;
      print(userInput);// Der UTF-8-Request, den du senden möchtest
      List<int> data = utf8.encode(password);
      try {
        await adminAuthenticationCharacteristic.setNotifyValue(true);
      }catch(e){
        print(e);
      }
      isAdminAuthenticationSubscriptionSet = true;
      adminAuthenticationSubscription = adminAuthenticationCharacteristic.value.listen((value) {
        List<int> response = value;
        bool authenticated = response[0] == 1;

        if(authenticated){
          leavePage();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TwoButtonsWidget(device: device)),
          );

        }else{
          setState(() {
            authErrorIsVisible = true;
          });
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              authErrorIsVisible = false;
            });
          });
        }
        // Hier kannst du die empfangenen Daten weiterverarbeiten
      });

      await adminAuthenticationCharacteristic.write(data);
    }
  }
  void handleDisconnect(BluetoothDevice device) async{
    leavePage();
    device.disconnect();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DeviceSelectionScreen()),
    );
  }

  void leavePage() async{
    if(isGuestAccessSubscriptionSet) {
      await guestAccessSubscription.cancel();
    }
    if(isAdminAuthenticationSubscriptionSet){
      await adminAuthenticationSubscription.cancel();
    }
  }

  void sendDataToDoor(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    // Suchen Sie die gewünschte Charakteristik in den gefundenen Diensten
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == "00000002-0000-1000-8000-00805f9b34fb") {
          guestAccessCharacteristic = c;
        }
      }

    }
    String uniqueIdentifier = await getDeviceIdentifier();
    String request = uniqueIdentifier; // Der UTF-8-Request, den du senden möchtest
    List<int> data = utf8.encode(request);
    try {
      await guestAccessCharacteristic.setNotifyValue(true);
    }catch(e){
      print(e);
    }
    isGuestAccessSubscriptionSet = true;
    guestAccessSubscription = guestAccessCharacteristic.value.listen((value) {
      String response = utf8.decode(value);
      setState(() {
        access = response;
      });
      print("Antwort erhalten: $response");
      // Hier kannst du die empfangenen Daten weiterverarbeiten
    });

    await guestAccessCharacteristic.write(data);

  }

  Future<String> getDeviceIdentifier() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.androidId;
  }
}