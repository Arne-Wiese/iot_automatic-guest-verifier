import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'overlay_dialog.dart';

class TwoButtonsWidget extends StatefulWidget {
  final BluetoothDevice device;

  TwoButtonsWidget({required this.device});

  @override
  _TwoButtonsWidgetState createState() => _TwoButtonsWidgetState();
}

class _TwoButtonsWidgetState extends State<TwoButtonsWidget> {

  late BluetoothCharacteristic adminManagingCharacteristic;
  late StreamSubscription<List<int>> adminManagingSubscription;
  bool isAdminManagingSubscriptionSet = false;
  bool visible = false;
  String text = '';
  Color color = Colors.green;

  @override
  Widget build(BuildContext context) {
    BluetoothDevice device = widget.device;
    return Scaffold(
      appBar: AppBar(
        title: Text('Managing guests'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: 200, // Anpassen der Breite des Buttons
              child: ElevatedButton(
                onPressed: () {
                  addGuest(device);
                },
                child: Text('Add guest'),
              ),
            ),
            SizedBox(height: 64), // Abstand zwischen den Buttons
            Container(
              width: 200, // Anpassen der Breite des Buttons
              child: ElevatedButton(
                onPressed: () {
                  deleteGuest(device);// Aktion für den zweiten Button
                },
                child: Text('Delete guest'),
              ),
            ),
            const SizedBox(height: 32),
            Visibility(
              visible: visible,
              child: Text(
                text,
                style: TextStyle(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addGuest(BluetoothDevice device) async {
    String? userInput = await showDialog<String>(
      context: context,
      builder: (context) => OverlayDialog( text: 'Adding guest with identifier:'),
    );
    if(userInput!=null && userInput != '') {
      manageGuests(0, device, userInput);
    }
  }

  Future<void> deleteGuest(BluetoothDevice device) async {
    String? userInput = await showDialog<String>(
        context: context,
        builder: (context) => OverlayDialog( text: 'Deleting guest with identifier:'),
    );
    if(userInput!=null && userInput != ''){
      manageGuests(1, device, userInput);
    }

  }

  Future<void> manageGuests(int i, BluetoothDevice device, String userInput) async {
    List<BluetoothService> services = await device.discoverServices();

    // Suchen Sie die gewünschte Charakteristik in den gefundenen Diensten
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == "00000006-0000-1000-8000-00805f9b34fb") {
          adminManagingCharacteristic = c;
        }
      }
    }
    List<int> data;
      if(i == 0){
        String order = 'a' + userInput;
        data = utf8.encode(order);
      }else {
        String order = 'd' + userInput;
        data = utf8.encode(order);
      }

      try {
        await adminManagingCharacteristic.setNotifyValue(true);
      }catch(e){
        print(e);
      }
      isAdminManagingSubscriptionSet = true;
      adminManagingSubscription = adminManagingCharacteristic.value.listen((value) {
        List<int> response = value;
        bool success = response[0] == 1;

        if(success && i == 0){
          setState(() {
            visible = true;
            text = 'Successfully added a guest!';
          });
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              visible = false;
              text = '';
            });
          });


        }else if (success && i == 0){
          setState(() {
            visible = true;
            text = 'Successfully deleted a guest!';
          });
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              visible = false;
              text = '';
            });
          });

        }else{
          setState(() {
            visible = true;
            text = 'Error! Please try again!';
            color = Colors.red;
          });
          Future.delayed(Duration(seconds: 3), () {
            setState(() {
              visible = false;
              text = '';
              color = Colors.green;
            });
          });
        }
        adminManagingSubscription.cancel();
        isAdminManagingSubscriptionSet = false;
        // Hier kannst du die empfangenen Daten weiterverarbeiten
      });

      await adminManagingCharacteristic.write(data);
    }

  }