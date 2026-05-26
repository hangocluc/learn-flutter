import 'package:learn_flutter/core/base/src/base_mapper.dart';

import '../../domain/entities/src/demo_entity.dart';
import '../model/demo_model_ui.dart';

class DemoMapper extends BaseMapper<DemoUIModel, DemoEntity> {
  DemoUIModel mapFromEntityToModel(DemoEntity? type) {
    return DemoUIModel(name: type?.name ?? '');
  }
}
