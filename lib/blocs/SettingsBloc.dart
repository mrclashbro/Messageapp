
import 'dart:async';

import 'package:message_app/models/Settings.dart';
import 'package:message_app/providers/SettingsProvider.dart';

/// Settings Bloc.

class SettingsBloc {
  final _sp = SettingsProvider.getInstance();
  final _ctrl = StreamController<Settings>();

  Stream get stream => _ctrl.stream;


  void dispose() {
    _ctrl.close();
  }

  void loadSettings() async {
    final Settings settings = await _sp.getSettings();
    _ctrl.sink.add(settings);
  }

  void updateSettings(Settings settings) async {
    await _sp.setSettings(settings);
    _ctrl.sink.add(settings);
  }
}