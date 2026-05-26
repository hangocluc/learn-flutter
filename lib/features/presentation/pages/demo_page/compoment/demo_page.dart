import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/core/extension/extention.dart';

import '../../../../../common/theme/app_color.dart';
import '../../../../../common/widget/app_switch/app_switch_sync.dart';
import '../../../cubits/demo_cubit/demo_cubit.dart';
import 'theme.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => DemoPageState();
}

class DemoPageState extends State<DemoPage> {
  // final appCubit = sl.get<DemoCubit>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('alo'),
      ),
      body: Container(
        color: AppColors.pink.pink50,
        child: Column(
          children: [
            AppSwitchComponentSync(
                iconPath: '',
                title: context.l10n.appTitle,
                onChange: (value) {
                  if (value) {
                    context.read<DemoCubit>().changeLanguage('ja');
                  } else {
                    context.read<DemoCubit>().changeLanguage('en');
                  }
                }),

            //change theme
            const ThemeScreenState()
          ],
        ),
      ),
    );
  }
}
