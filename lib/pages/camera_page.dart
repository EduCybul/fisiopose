import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:fisiopose/utils/Movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/model_inference_service.dart';
import '../../services/service_locator.dart';
import '../../utils/isolate_utils.dart';

import '../widgets/model_camera_preview.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({
    super.key, required this.MovementObject,
  });

  final Movement? MovementObject;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late CameraDescription _cameraDescription;

  late bool _isRun;
  bool _predicting = false;
  bool _draw = false;

  late IsolateUtils _isolateUtils;
  late IsolateUtils _isolateUtilsImage;
  late ModelInferenceService _modelInferenceService;

  Uint8List? _captureImage;
  final GlobalKey<ModelCameraPreviewState> _modelCameraPreviewKey = GlobalKey<ModelCameraPreviewState>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenUtil.init(context, designSize: const Size(360, 690));
     // _minTextAdapt = ScreenUtil().setSp(12);
    });
    _modelInferenceService = locator<ModelInferenceService>();
    _inititalizeServices();
    _initStateAsync();
    super.initState();
  }

  Future<void> _inititalizeServices() async {
    _modelInferenceService = locator<ModelInferenceService>();
    _modelInferenceService.setModelConfig();
  }

  void _initStateAsync() async {
    _isolateUtils = IsolateUtils();
    _isolateUtilsImage = IsolateUtils();
    await _isolateUtilsImage.initIsolate();
    await _isolateUtils.initIsolate();
    await _initCamera();
    _predicting = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isolateUtils.dispose();
    _isolateUtilsImage.dispose();
    _modelInferenceService.inferenceResults = null;


    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraDescription = _cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
    );
    _isRun = false;
    _onNewCameraSelected(_cameraDescription);
  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    _cameraController = CameraController(

      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,

    );

    _cameraController!.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController!.value.hasError) {
        _showInSnackBar(
            'Camera error ${_cameraController!.value.errorDescription}');
      }
    });

    try {
      await _cameraController!.initialize().then((value) {
        if (!mounted) return;
      });
      await _cameraController!.setFlashMode(FlashMode.off);//Asegurarnos de que el flash no se enciendan.
    } on CameraException catch (e) {
      _showInSnackBar('Error: ${e.code}\n${e.description}');
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showInSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 690));
    //_minTextAdapt = ScreenUtil().setSp(12);


    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (_isRun) {
          _imageStreamToggle;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar,
        body: ModelCameraPreview(
          key: _modelCameraPreviewKey,
          cameraController: _cameraController,
          movement: widget.MovementObject,
          draw: _draw,
          imageData: _captureImage,
        ),
        floatingActionButton: _buildFloatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar get _buildAppBar => AppBar(
    title: Text(
       widget.MovementObject?.movementName ?? '',
      style: TextStyle(
          color: Colors.black,
          fontSize: ScreenUtil().setSp(20),
          fontWeight: FontWeight.bold),
    ),
  );

  Row get _buildFloatingActionButton => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      IconButton(
        onPressed: () => _cameraDirectionToggle,
        color: Colors.white,
        iconSize: ScreenUtil().setWidth(30.0),
        icon: const Icon(
          Icons.cameraswitch,
        ),
      ),
      IconButton(
        onPressed: () => _imageToggle,
        color: Colors.white,
        iconSize: ScreenUtil().setWidth(30.0),
        icon: const Icon(
          Icons.add_a_photo,
        ),
      ),
      IconButton(
        onPressed: () => _imageStreamToggle,
        color: Colors.white,
        iconSize: ScreenUtil().setWidth(30.0),
        icon: const Icon(
          Icons.filter_center_focus,
        ),
      ),
    ],
  );

  void get _imageToggle async {
    final XFile imageFile = await _cameraController!.takePicture() ;
    final Uint8List imageData = await imageFile.readAsBytes();

    //final img.Image? image = img.decodeImage(imageData);
    //final CameraImage convertedCameraimage = convertUint8ListToCameraImage(imageData);
    setState(() {
      _draw = true;
      _captureImage = imageData;
    });

    print('Image size: ${imageData.length}');

    await _inferenceWithImage(imageData);
    final points = locator<ModelInferenceService>().inferenceResults?['point']
        ?? locator<ModelInferenceService>().inferenceResults?['point'] ?? [];
    _modelCameraPreviewKey.currentState?.updateInferenceResults(points);
  }
  void get  _imageStreamToggle{
    setState(() {
      _draw = !_draw;
    });

    _isRun = !_isRun;
    if (_isRun) {

      _cameraController!.startImageStream(
            (CameraImage cameraImage) async {
              await _inference(cameraImage: cameraImage);
              final points = locator<ModelInferenceService>().inferenceResults?['point']
                  ?? locator<ModelInferenceService>().inferenceResults?['point'] ?? [];
              print('Points from inference: $points');
              _modelCameraPreviewKey.currentState?.updateInferenceResults(points);
            },
      );
    } else {
      _cameraController!.stopImageStream();
    }
  }

  void get _cameraDirectionToggle {
    setState(() {
      _draw = false;
    });
    _isRun = false;
    if (_cameraController!.description.lensDirection ==
        _cameras.first.lensDirection) {
      _onNewCameraSelected(_cameras.last);
    } else {
      _onNewCameraSelected(_cameras.first);
    }
  }
  Future<void> _inferenceWithImage(Uint8List imageData) async {
    if (!mounted) return;

    if (_modelInferenceService.model.getInterpreter!= null) {
      if (_predicting || !_draw) {
        return;
      }

      setState(() {
        _predicting = true;
        _draw=true;
      });

      if (_draw) {
        print('Starting inference with Image');
        await _modelInferenceService.inferenceWithUint8List(
          isolateUtils: _isolateUtilsImage,
          imageData: imageData,
        );
        print("Inference Image done");
      }
      setState(() {
        _predicting = false;
      });
    }
  }
  Future<void> _inference({required CameraImage cameraImage}) async {
    if (!mounted) return;

    if (_modelInferenceService.model.getInterpreter!= null) {
      if (_predicting || !_draw) {
        return;
      }

      setState(() {
        _predicting = true;
      });

      if (_draw) {
        print('Starting inference with camera image Stream');
        await _modelInferenceService.inference(
          isolateUtils: _isolateUtils,
          cameraImage: cameraImage,
        );
        print('Inference done');

        final points = locator<ModelInferenceService>().inferenceResults?['point']
            ?? locator<ModelInferenceService>().inferenceResults?['point'] ?? [];
        _modelCameraPreviewKey.currentState?.updateInferenceResults(points);


      }
      //final points = locator<ModelInferenceService>().inferenceResultsImage?['point'] ?? locator<ModelInferenceService>().inferenceResults?['point'];
      //print('Points from streaming inference: $points');
      //_modelCameraPreviewKey.currentState?.updateInferenceResults(points);

      setState(() {
        _predicting = false;
      });
    }
  }

}
