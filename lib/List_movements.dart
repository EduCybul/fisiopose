import 'package:fisiopose/pages/PointSelectionPage.dart';
import 'package:fisiopose/pages/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:fisiopose/utils/Movement.dart';

import 'Start.dart';

class ListMovements extends StatefulWidget {
  const ListMovements({super.key, required this.index});

  final int index;

  @override
  _ListMovementsState createState() => _ListMovementsState();
}

class _ListMovementsState extends State<ListMovements> {
  List<Movement> movements = [
    Movement(movementName: 'Flexion hombro derecho', keypoints: [14, 12, 24], maxAngle: 90, imagepath: 'assets/image/flexion-hombro-derecho.png'),
    Movement(movementName: 'Flexion hombro izquierdo', keypoints: [13, 11, 23], maxAngle: 90,  imagepath: 'assets/image/flexion-hombro-izquierdo.png'),
    Movement(movementName: 'Flexion cadera izquierda', keypoints: [28, 24, 27], maxAngle: 90, imagepath: 'assets/image/flexion-cadera-izquierda.png'),
    Movement(movementName: 'Flexion cadera derecha', keypoints: [27, 23, 28], maxAngle: 90,  imagepath: 'assets/image/flexion-cadera-derecha.png'),
    Movement(movementName: 'Flexion codo', keypoints: [16, 14, 12], maxAngle: 90,  imagepath: 'assets/image/flexion-codos.png'),
    Movement(movementName: 'Abduccion hombro', keypoints: [14, 12, 24], maxAngle: 90,  imagepath: 'assets/image/flexion_hombro_frontal.png'),
    Movement(movementName: 'Flexion muneca derecha', keypoints: [18, 16, 14], maxAngle: 90,  imagepath: 'assets/image/flexion-hombro-derecho.png'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de movimientos'),
        backgroundColor: Colors.deepPurple,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 25,
          color: Colors.black,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: ()  => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Start(() {})),
              ),
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
        child: ListView.builder(
          itemCount: movements.length + 1,
          itemBuilder: (context, index) {
            if (index == movements.length) {
              return _addNewMovementItem(context);
            } else {
              return _movementItem(context, movements[index]);
            }
          },
        ),
      ),
    );
  }

  Widget _movementItem(BuildContext context, Movement movement) {
    return Card(
      margin: const EdgeInsets.all(20.0),
      child: InkWell(
        onTap: () => _onTapCamera(context, movement),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(movement.imagepath, scale: 2), // Placeholder image
              const SizedBox(height: 10),
              Text(
                movement.movementName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addNewMovementItem(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: () => _onTapAddNewMovement(context),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 50,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 10),
              const Text(
                'Añadir nuevo movimiento',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTapAddNewMovement(BuildContext context) async {
    final newMovement = await Navigator.push<Movement>(
      context,
      MaterialPageRoute(
        builder: (context) => PointSelectionPage(),
      ),
    );

    if (newMovement != null) {
      setState(() {
        movements.add(newMovement);
      });
    }
  }

  void _onTapCamera(BuildContext context, Movement movement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(MovementObject: movement),
      ),
    );
  }
}