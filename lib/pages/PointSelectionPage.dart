import 'package:fisiopose/utils/Movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para rootBundle
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class PointSelectionPage extends StatefulWidget {
  @override
  _PointSelectionPageState createState() => _PointSelectionPageState();
}

class _PointSelectionPageState extends State<PointSelectionPage> {
  List<int> keypoints = List<int>.generate(33, (int index) => index);
  List<int> Angulos = [180, 90];

  List<String> availableModels = [];
  int? selectedKeypoint1;
  int? selectedKeypoint2;
  int? selectedKeypoint3;
  String movementName = '';
  int? maxAngle;
  String? imagePath;
  String? selectedModelName;

  @override
  void initState() {
    super.initState();
    _loadModelList();
  }

  Future<void> _loadModelList() async {
    try {
      final String modelsTxt = await rootBundle.loadString('assets/models/models.txt');
      setState(() {
        availableModels = modelsTxt
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.endsWith('.tflite'))
            .toList();
      });
    } catch (e) {
      setState(() {
        availableModels = [];
      });
    }
  }

  Future<void> _pickImage() async {
    PermissionStatus status;
    if (Platform.isAndroid && (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33) {
      status = await Permission.photos.request();
    } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se requiere permiso para seleccionar imágenes.'),
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
              DropdownButtonFormField<String>(
                value: selectedModelName,
                items: availableModels.map((String model) {
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text(model),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedModelName = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Modelo TFLite',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Seleccionar Imagen'),
              ),
              const SizedBox(height: 5),
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.file(
                    File(imagePath!),
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (movementName.isNotEmpty &&
                        selectedKeypoint1 != null &&
                        selectedKeypoint2 != null &&
                        selectedKeypoint3 != null &&
                        maxAngle != null &&
                        imagePath != null &&
                        selectedModelName != null) {
                      Movement movement = Movement(
                        movementName: movementName,
                        keypoints: [selectedKeypoint1!, selectedKeypoint2!, selectedKeypoint3!],
                        maxAngle: maxAngle!,
                        imagepath: imagePath!,
                        modelName: selectedModelName!, // Usa el modelo seleccionado
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