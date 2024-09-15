import 'package:fisiopose/utils/Movement.dart';
import 'package:flutter/material.dart';

import 'camera_page.dart';

class PointSelectionPage extends StatefulWidget {
  @override
  _PointSelectionPageState createState() => _PointSelectionPageState();
}

class _PointSelectionPageState extends State<PointSelectionPage> {
  // Generate a list of integers from 0 to 32 for keypoints
  List<int> keypoints = List<int>.generate(33, (int index) => index);
  List<int> Angulos = [180, 90];

  int? selectedKeypoint1;
  int? selectedKeypoint2;
  int? selectedKeypoint3;
  String movementName = '';
  int? maxAngle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Define Movement'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(  // Wrap content inside SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the Mediapipe skeleton image
              Image.asset(
                'assets/image/pose_landmarks_index.png', // Your image path
                height: 400,  // Set a fixed height
                width: double.infinity,  // Stretch to full width of the container
                fit: BoxFit.contain,  // Adjust the fit so it scales properly
              ),
              const SizedBox(height: 20),
              // Movement Name Input
              TextField(
                onChanged: (value) => movementName = value,
                decoration: const InputDecoration(
                  labelText: 'Movement Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Dropdown for First Keypoint
              DropdownButtonFormField<int>(
                value: selectedKeypoint1,
                items: keypoints.map((int keypoint) {
                  return DropdownMenuItem<int>(
                    value: keypoint,
                    child: Text(keypoint.toString()), // Display the number
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedKeypoint1 = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Primer punto (0-32)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),

              // Dropdown for Second Keypoint
              DropdownButtonFormField<int>(
                value: selectedKeypoint2,
                items: keypoints.map((int keypoint) {
                  return DropdownMenuItem<int>(
                    value: keypoint,
                    child: Text(keypoint.toString()), // Display the number
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedKeypoint2 = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Segundo punto (0-32)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),

              // Dropdown for Third Keypoint
              DropdownButtonFormField<int>(
                value: selectedKeypoint3,
                items: keypoints.map((int keypoint) {
                  return DropdownMenuItem<int>(
                    value: keypoint,
                    child: Text(keypoint.toString()), // Display the number
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedKeypoint3 = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tercer punto (0-32)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),

              // Maximum Angle Input
              DropdownButtonFormField<int>(
                value: maxAngle,
                items:Angulos.map((int angulo) {
                  return DropdownMenuItem<int>(
                    value: angulo,
                    child: Text(angulo.toString()), // Display the number
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    maxAngle = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Angulo Maximo(grados)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (movementName.isNotEmpty &&
                        selectedKeypoint1 != null &&
                        selectedKeypoint2 != null &&
                        selectedKeypoint3 != null &&
                        maxAngle != null) {
                      Movement movement = Movement(
                        movementName: movementName,
                        keypoints: [selectedKeypoint1!, selectedKeypoint2!, selectedKeypoint3!],
                        maxAngle: maxAngle!,
                      );
                      // Create the movement with the selected keypoints and angle
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => CameraPage( MovementObject: movement)
                            ,)
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Completa todos los campos'),
                        ),
                      );
                    }
                  },
                  child: const Text('Crear Movimiento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}