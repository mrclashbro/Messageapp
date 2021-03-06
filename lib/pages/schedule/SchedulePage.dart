import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:message_app/blocs/MessageBloc.dart';

import 'package:message_app/models/Message.dart';
import 'package:message_app/pages/schedule/ArchivedMessages.dart';
import 'package:message_app/pages/schedule/CreateOrEditSmsMessagePage.dart';
import 'package:message_app/pages/settings/SettingsPage.dart';
import 'package:message_app/providers/DialogProvider.dart';
import 'package:message_app/providers/ScheduleProvider.dart';
import 'package:sms/sms.dart';
import './Schedule.dart';
import './sms.dart';

class SchedulePage extends StatefulWidget {
  SchedulePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

enum PopUpMenuValues {
  deleteAll,
  refreshMessages,
  appSettings,
  archivedMessages,
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ScheduleProvider _scheduleProvider = ScheduleProvider();
  TabController _tabController;
  final _messageBloc = MessageBloc();
  List<Message> _messages;
  Timer _refreshTimer;

  static const _iconSize = 28.0;

  /// load messages.
  void _refreshMessages() => _messageBloc.loadMessages();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _refreshMessages();

    _scheduleProvider.onMessageProcessed =
        (Message message) => _messageBloc.updateMessage(message);
    _scheduleProvider.start(Duration(seconds: 15));

    _refreshTimer =
        Timer.periodic(Duration(seconds: 30), (Timer t) => _refreshMessages());
  }

  @override
  void dispose() {
    super.dispose();
    _messageBloc.dispose();
    _refreshTimer.cancel();
    _scheduleProvider.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('state changed: $state');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SchedulePage.build()');

    return Scaffold(
        appBar: AppBar(
            title: Text(widget.title),
            actions: <Widget>[
              PopupMenuButton<PopUpMenuValues>(
                tooltip: '',
                onSelected: _onPopupSelected,
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<PopUpMenuValues>>[
                  PopupMenuItem<PopUpMenuValues>(
                    enabled: _messages != null && _messages.isNotEmpty,
                    value: PopUpMenuValues.deleteAll,
                    child: ListTile(
                        leading: Icon(Icons.delete_forever),
                        title: Text('Delete all messages',
                            style: TextStyle(
                                color: _messages != null && _messages.isNotEmpty
                                    ? Colors.black87
                                    : Colors.grey))),
                  ),
                  const PopupMenuItem<PopUpMenuValues>(
                    value: PopUpMenuValues.refreshMessages,
                    child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Refresh messages')),
                  ),
                  const PopupMenuItem<PopUpMenuValues>(
                    value: PopUpMenuValues.appSettings,
                    child: ListTile(
                        leading: Icon(Icons.settings), title: Text('Settings')),
                  ),
                ],
              )
            ],
            bottom: TabBar(
              indicatorColor: Colors.deepOrange,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.white,
              controller: _tabController,
              tabs: const <Widget>[
                Tab(icon: Icon(Icons.all_inbox, size: _iconSize)),
                Tab(icon: Icon(Icons.schedule, size: _iconSize)),
                Tab(icon: Icon(Icons.mark_chat_read, size: _iconSize)),
                Tab(icon: Icon(Icons.error, size: _iconSize)),
              ],
            )),
        backgroundColor: Colors.white,
        body: StreamBuilder<List<Message>>(
          stream: _messageBloc.stream,
          initialData: null,
          builder:
              (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
            final List<Message> all = snapshot.data
                ?.takeWhile((msg) => !msg.isArchived)
                ?.toList(); // gets non-archived messages.
            final pending = all
                ?.takeWhile((msg) => msg.status == MessageStatus.PENDING)
                ?.toList();
            final failed = all
                ?.takeWhile((msg) => msg.status == MessageStatus.FAILED)
                ?.toList();
            final sent = all
                ?.takeWhile((msg) => msg.status == MessageStatus.SENT)
                ?.toList();

            _messages = snapshot.data; // take all messages.

            return TabBarView(
              controller: _tabController,
              children: <Widget>[
                Schedule(all, () => _refreshMessages()),
                Schedule(pending, () => _refreshMessages()),
                Schedule(sent, () => _refreshMessages()),
                Schedule(failed, () => _refreshMessages()),
              ],
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton(
                heroTag: null,
                onPressed: _onCreateMessage,
                child: Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.redAccent,
              ),
              FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SendSms()));
                },
                child: Icon(Icons.send, color: Colors.white),
                backgroundColor: Colors.redAccent,
              )
            ],
          ),
        ));
  }

  void _onPopupSelected(PopUpMenuValues value) {
    switch (value) {
      case PopUpMenuValues.deleteAll:
        DialogProvider.showConfirmation(
            title: Icon(Icons.delete_forever),
            content: Text('Are you sure delete all messages?'),
            context: context,
            onYes: () {
              _messageBloc.deleteAllMessages();
              _refreshMessages();
            });
        break;

      case PopUpMenuValues.refreshMessages:
        _refreshMessages();
        break;

      case PopUpMenuValues.archivedMessages:
        final List<Message> messages =
            _messages.takeWhile((message) => message.isArchived).toList();

        Navigator.push(
          context,
          MaterialPageRoute<bool>(
              builder: (context) => ArchivedMessages(messages)),
        ).then((bool result) {
          _refreshMessages();
        });
        break;

      case PopUpMenuValues.appSettings:
        Navigator.push(
          context,
          MaterialPageRoute<bool>(builder: (context) => SettingsPage()),
        ).then((bool result) {
          _refreshMessages();
        });
        break;

      default:
        break;
    }
  }

  void _onCreateMessage() {
    Navigator.push(
      context,
      MaterialPageRoute<bool>(
          builder: (context) => CreateOrEditSmsMessagePage(MessageMode.create)),
    ).then((bool result) {
      _refreshMessages();
    });
  }
}
