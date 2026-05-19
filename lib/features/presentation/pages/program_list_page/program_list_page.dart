import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_java/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_java/features/presentation/cubits/program_cubit/program_cubit.dart';
import 'package:learn_java/features/presentation/pages/program_detail_page/program_detail_page.dart';

class ProgramListPage extends StatefulWidget {
  const ProgramListPage({super.key});

  @override
  State<ProgramListPage> createState() => _ProgramListPageState();
}

class _ProgramListPageState extends State<ProgramListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProgramCubit>().loadPrograms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Programs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProgramCubit>().refreshData();
            },
          ),
        ],
      ),
      body: BlocBuilder<ProgramCubit, ProgramCubitState>(
        builder: (context, state) {
          if (state is ProgramCubitLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProgramCubitError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProgramCubit>().refreshData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ProgramCubitLoaded) {
            if (state.programs.isEmpty) {
              return const Center(
                child: Text(
                  'No programs available',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProgramCubit>().refreshData();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.programs.length,
                itemBuilder: (context, index) {
                  final program = state.programs[index];
                  return _buildProgramCard(program);
                },
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProgramCard(ProgramEntity program) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramDetailPage(program: program),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.code,
                  size: 30,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name ?? 'Untitled Program',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${program.programDetails?.length ?? 0} examples',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
