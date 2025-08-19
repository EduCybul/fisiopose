import 'package:fisiopose/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:fisiopose/Home.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  print('Widgets binding initialized');

  setupLocator();
  print('Service locator set up');
  runApp( const Home());
}