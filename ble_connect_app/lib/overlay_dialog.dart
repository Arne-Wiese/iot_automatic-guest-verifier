import 'package:flutter/material.dart';

class OverlayDialog extends StatefulWidget {
  @override
  _OverlayDialogState createState() => _OverlayDialogState();
}

class _OverlayDialogState extends State<OverlayDialog> {
  TextEditingController _textEditingController = TextEditingController();
  String userInput = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Schließe den Dialog, wenn außerhalb des Textfeldes getippt wird
        Navigator.of(context).pop(userInput);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Passwort:'),
                SizedBox(height: 10),
                TextField(
                  controller: _textEditingController,
                  onChanged: (value) {
                    setState(() {
                      userInput = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Schließe den Dialog und gebe den userInput zurück
                    Navigator.of(context).pop(userInput);
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
