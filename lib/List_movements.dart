import 'package:fisiopose/pages/camera_page.dart';
import 'package:fisiopose/services/model_inference_service.dart';
import 'package:fisiopose/services/service_locator.dart';
import 'package:flutter/material.dart';



class ListMovements extends StatelessWidget{
  const ListMovements({super.key, required this.index});

  final int index;
  @override
  Widget build (context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of movements'),
        backgroundColor: Colors.deepPurple,
        titleTextStyle:
        const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.black
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.deepPurple],
            begin: Alignment.centerLeft,
            end: Alignment.center,
            tileMode: TileMode.mirror,
          ),
        ),
        child: Builder(
            builder: (BuildContext innerContext) {
              return GridView.count(
                  crossAxisCount: 2,
                  children: [
                    //FIRST POSE
                    InkWell(
                      onTap: () => _onTapCamera(innerContext),
                      child:Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children:
                          [
                            Image.asset('assets/image/flexion-hombro.png'),
                            const Text('Flexion de hombro', style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,

                            ),),
                          ],
                        ),
                      ),
                    ),
                    //SECOND POSE
                    InkWell(
                      onTap:() { ScaffoldMessenger.of(innerContext).showSnackBar(
                        const SnackBar(
                          content: Text('Tap'),
                        ),);
                      },
                      child:Image.asset('assets/image/fisio.png'),
                    )
                  ]
              );
            }
        ),
      ),
    );

  }

  void _onTapCamera(BuildContext context){
    //locator<ModelInferenceService>().setModelConfig(index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(index: index),
      ),
    );
  }

}