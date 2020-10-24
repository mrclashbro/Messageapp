import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:message_app/models/Message.dart';
import 'package:message_app/pages/schedule/Schedule.dart';

class ArchivedMessages extends StatefulWidget {
  final List<Message> messages;

  const ArchivedMessages(this.messages);

  _ArchivedMessagesState createState() => _ArchivedMessagesState();
}

class _ArchivedMessagesState extends State<ArchivedMessages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Archived Messages"),
      ),
      body: Schedule(widget.messages)
    );
  }
}