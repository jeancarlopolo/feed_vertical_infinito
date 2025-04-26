import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:atproto/atproto.dart';
import 'main_app.dart';

Future<void> main() async {
  setup();
  runApp(const MainApp());
}

void setup() {
  GetIt.instance.registerSingleton<ATProto>(ATProto.anonymous());
}


