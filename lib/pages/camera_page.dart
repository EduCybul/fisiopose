import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/model_inference_service.dart';
import '../../services/service_locator.dart';
import '../../utils/isolate_utils.dart';
import 'package:fisiopose/widgets//model_camera_preview.dart';

import '../services/pose_service.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({
    required this.index,
    Key? key,
  }) : super(key: key);

  final int index;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {

  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late CameraDescription _cameraDescription;

  late bool _isRun;
  bool _predicting = false;
  bool _draw = true;

  late IsolateUtils _isolateUtils;
  late ModelInferenceService _modelInferenceService;
  late Pose _poseService;
  late double _minTextAdapt ;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenUtil.init(context, designSize: Size(360, 690));
      _minTextAdapt = ScreenUtil().setSp(12);
    });

    _modelInferenceService = locator<ModelInferenceService>();

    _poseService = Pose(interpreter: null);
    _poseService.loadModel().then((_) { // Load the model before initializing the state
      _initStateAsync();
    });
  }




  void _initStateAsync() async {
    _isolateUtils = IsolateUtils();
    await _isolateUtils.initIsolate();
    await _initCamera();
    _predicting = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    _isolateUtils.dispose();
    _modelInferenceService.inferenceResults = null;
    super.dispose();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraDescription = _cameras[1];
    _isRun = false;
    _onNewCameraSelected(_cameraDescription);
    print("Controlador de cámara creado con configuración específica");

  }

  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    print('Camera selected: $cameraDescription');
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.low,
      enableAudio: false,
    );

    _cameraController!.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController!.value.hasError) {
        _showInSnackBar(
            'Camera error ${_cameraController!.value.errorDescription}');
        print("*******************Cámara inicializada correctamente");

      }
    });

    try {
      await _cameraController!.initialize().then((value) {
        if (!mounted) return;
      });
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
    ScreenUtil.init(context, designSize: Size(360, 690));
    _minTextAdapt = ScreenUtil().setSp(12);


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
          cameraController: _cameraController,
          index: widget.index,
          draw: _draw,
        ),
        floatingActionButton: _buildFloatingActionButton,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  AppBar get _buildAppBar => AppBar(
    title: Text(
      'title',
      style: TextStyle(
          color: Colors.black,
          fontSize: ScreenUtil().setSp(28),
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
      IconButton(//Boton que realiza la predicción
        onPressed: () => _imageStreamToggle,
        color: Colors.white,
        iconSize: ScreenUtil().setWidth(30.0),
        icon: const Icon(
          Icons.filter_center_focus,
        ),
      ),
    ],
  );

  void get _imageStreamToggle {
    print('Image stream toggle button pressed');
    setState(() {
      _draw = !_draw;
    });

    _isRun = !_isRun;
    if (_isRun) {
      print('Starting image stream');
      print('_draw: $_draw');
      print('_modelInferenceService.model.getInterpreter: ${_modelInferenceService.model.getInterpreter}');
      print('_predicting: $_predicting');

      _cameraController!.startImageStream(
            (CameraImage cameraImage) async =>
        await _inference(cameraImage: cameraImage),
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
  Future<void> loadAndInference({required CameraImage cameraImage}) async {
    print('************Loading INFERENCE');
    await _modelInferenceService.poseService.loadModel();
    _inference(cameraImage: cameraImage);
  }
  Future<void> _inference({required CameraImage cameraImage}) async {
    loadAndInference(cameraImage: cameraImage);
    if (!mounted) return;

    if (_modelInferenceService.poseService.getInterpreter != null) {
      if (_predicting || !_draw) {
        print('Predicting: $_predicting, Draw: $_draw');
        return;
      }

      setState(() {
        _predicting = true;
      });

      if (_draw) {
        print('Calling inference method');
        await _modelInferenceService.inference(
          isolateUtils: _isolateUtils,
          cameraImage: cameraImage,
        );
        setState(() {});
      }

      setState(() {
        _predicting = false;
      });
    }else{
      print('**************Model interpreter is null');
    }
  }
}