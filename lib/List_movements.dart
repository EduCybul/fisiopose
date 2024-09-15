import 'package:fisiopose/pages/PointSelectionPage.dart';
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
        title: const Text('Lista de movimientos'),
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
                      _movementItem(innerContext, 'assets/image/flexion-hombro-derecho.png', 'Flexion hombro derecho'),
                      _movementItem(innerContext, 'assets/image/flexion-hombro-izquierdo.png', 'Flexion hombro izquierdo'),
                      _movementItem(innerContext, 'assets/image/flexion-cadera-izquierda.png', 'Flexion cadera izquierda'),
                      _movementItem(innerContext, 'assets/image/flexion-cadera-derecha.png', 'Flexion cadera derecha'),
                      _movementItem(innerContext, 'assets/image/flexion-codos.png', 'Flexion codo'),
                      _movementItem(innerContext, 'assets/image/abduccion-hombro.jpg', 'Abduccion hombro'),
                    _movementItem(innerContext, 'assets/image/flexion-muneca-derecha.jpeg', 'Flexion muneca derecha'),
                    _addNewMovementItem(innerContext),
                    ]
              );
            }
        ),
      ),
    );

  }
  Widget _movementItem(BuildContext context, String imagepath, String title ){
    return InkWell(
      onTap : () => _onTapCamera(context, title),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Image.asset(imagepath, scale: 2),
            Text(
              title,
              style: const TextStyle(
                backgroundColor: Colors.black,
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],

        )
      )
    );

  }

  Widget _addNewMovementItem(BuildContext context) {
    return InkWell(
      onTap: () => _onTapAddNewMovement(context),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: const [
            Icon(
              Icons.add_circle_outline,
              size: 50,
              color: Colors.white,
            ),
            Text(
              'Añadir nuevo movimiento',
              style: TextStyle(
                backgroundColor: Colors.black,
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onTapAddNewMovement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PointSelectionPage(), // Navigate to the new page
      ),
    );
  }
}

  void _onTapCamera(BuildContext context, String movement){
    //locator<ModelInferenceService>().setModelConfig(index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(movement: movement),
      ),
    );
  }

