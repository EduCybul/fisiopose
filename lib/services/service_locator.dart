import 'package:get_it/get_it.dart';
import 'model_inference_service.dart';
import 'pose_service.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerSingleton<Pose>(Pose());
  locator.registerLazySingleton<ModelInferenceService>(
          () => ModelInferenceService());
}