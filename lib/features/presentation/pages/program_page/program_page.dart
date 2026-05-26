import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/features/presentation/cubits/program_cubit/program_cubit.dart';
import 'package:learn_flutter/features/presentation/pages/program_list_page/program_list_page.dart';
import 'package:learn_flutter/main.dart';

class ProgramPage extends StatelessWidget {
  const ProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt.get<ProgramCubit>()..loadPrograms(),
      child: const ProgramListPage(),
    );
  }
}
