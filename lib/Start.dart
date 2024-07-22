
import 'package:flutter/material.dart';

class Start extends StatelessWidget{
  const Start(this.home,{super.key});

  final void Function() home;

  @override
  Widget build(context){
    return  Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/image/fisio.png',
            width: 300),
          const SizedBox(height: 50),
          const Text('Pose!'),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: home,
            style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                foregroundColor: Colors.white),
            label: const Text('Start'), icon: const Icon(Icons.arrow_circle_right_rounded),)
        ],
      ),
    );

  }




}