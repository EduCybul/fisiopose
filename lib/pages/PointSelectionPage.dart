import 'package:fisiopose/utils/Movement.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_page.dart';
import 'package:permission_handler/permission_handler.dart';

class PointSelectionPage extends StatefulWidget {
  @override
  _PointSelectionPageState createState() => _PointSelectionPageState();
}

class _PointSelectionPageState extends State<PointSelectionPage> {
  List<int> keypoints = List<int>.generate(33, (int index) => index);
  List<int> Angulos = [180, 90];

  int? selectedKeypoint1;
  int? selectedKeypoint2;
  int? selectedKeypoint3;
  String movementName = '';
  int? maxAngle;
  String? imagePath;

  Future<void> _pickImage() async {
    PermissionStatus status = await Permission.storage.status;

    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          imagePath = image.path;
        });
      }
    } else {
      // Handle the case when the permission is not granted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to pick images.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Define Movement'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/image/pose_landmarks_index.png',
                height: 400,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => movementName = value,
                decoration: const InputDecoration(
                  labelText: 'Movement Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: selectedKeypoint1,
                items: keypoints.map((int keypoint) {
                  return DropdownMenuItem<int>(
                    value: keypoint,
                    child: Text(keypoint.toString()),
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
              DropdownButtonFormField<int>(
                value: selectedKeypoint2,
                items: keypoints.map((int keypoint) {
                  return DropdownMenuItem<int>(
                    value: keypoint,
                    child: Text(keypoint.toString()),
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
              DropdownButtonFormField<int>(
                value: selectedKeypoint3,
                items: keypoints.map((int keypoint) {
                  return DropdownMenuItem<int>(
                    value: keypoint,
                    child: Text(keypoint.toString()),
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
              DropdownButtonFormField<int>(
                value: maxAngle,
                items: Angulos.map((int angulo) {
                  return DropdownMenuItem<int>(
                    value: angulo,
                    child: Text(angulo.toString()),
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
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Seleccionar Imagen'),
              ),
              const SizedBox(height: 5),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (movementName.isNotEmpty &&
                        selectedKeypoint1 != null &&
                        selectedKeypoint2 != null &&
                        selectedKeypoint3 != null &&
                        maxAngle != null &&
                        imagePath != null) {
                      Movement movement = Movement(
                        movementName: movementName,
                        keypoints: [selectedKeypoint1!, selectedKeypoint2!, selectedKeypoint3!],
                        maxAngle: maxAngle!,
                        imagepath: imagePath!,
                      );
                      Navigator.pop(context, movement);
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