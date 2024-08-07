import 'package:flutter/material.dart';
import 'package:khata_connect/helpers/appLocalizations.dart';

class Inbox extends StatefulWidget {
  const Inbox({super.key});

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Center(child: Text("Chatting"),),
      ),
    );
  }
}
