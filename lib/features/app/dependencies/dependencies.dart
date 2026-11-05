import 'package:get_it/get_it.dart';

import '../../../common/common_di.dart';
import '../../../core/navigator/navigator_service.dart';
import '../../../core/navigator/main_tab_navigator.dart';
import 'cubit_dependencies.dart';
import 'network_dependencies.dart';
import 'repository_dependencies.dart';
import 'usecase_dependencies.dart';

Future<void> registerDependencies(GetIt sl) async {
  await commonDI(sl);

  await registerNetworkDependencies(sl);
  await registerRepositoryDI(sl);
  await registerUseCaseDI(sl);
  await registerCubitDI(sl);
}

Future<void> registerNavigator(GetIt sl) async {
  sl.registerLazySingleton(() => NavigationService());
  sl.registerLazySingleton(() => MainTabNavigator());
}
