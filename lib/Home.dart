import 'package:fisiopose/List_movements.dart';
import 'package:flutter/material.dart';

import 'Start.dart';

class Home extends StatefulWidget{
const Home({super.key});

  @override
  State<Home> createState(){
    return _Home();
  }

}


class _Home extends State<Home> {

  var activeScreen = 'start-screen';

  void switchscreen(){
    setState(() {
      activeScreen = 'list-movements';
    });

  }

  @override
  Widget build(context) {
    Widget screenWidget = Start(switchscreen);

    if(activeScreen=='list-movements'){
      screenWidget = const ListMovements(index: 0,);

    }

    return MaterialApp(
        home: Scaffold(
          body: Container(
              decoration: const BoxDecoration(
                  gradient:LinearGradient(
                      colors:[Colors.purple,Colors.indigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      tileMode: TileMode.mirror)  ),
              child:  screenWidget
          ),
        )
    );
  }
}
