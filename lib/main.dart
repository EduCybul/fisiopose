import 'package:fisiopose/services/pose_service.dart';
import 'package:fisiopose/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:fisiopose/Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  Pose pose = Pose();
  await pose.initialize();

  runApp( Home());


}