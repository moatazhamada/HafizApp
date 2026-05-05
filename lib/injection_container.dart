import 'package:get_it/get_it.dart';

import 'di/di_core.dart';
import 'di/di_qf.dart';
import 'di/di_features.dart';

final sl = GetIt.instance;

Future<void> init() async {
  registerCoreDependencies();
  registerQfDataSources();
  registerFeatureDependencies();
}
