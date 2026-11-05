import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/common/utils/program_progress_utils.dart';
import 'package:learn_flutter/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_flutter/features/presentation/widgets/app_loading_widget.dart';
import 'package:learn_flutter/features/presentation/cubits/program_cubit/program_cubit.dart';
import 'package:learn_flutter/features/presentation/pages/dart_playground_page/dart_playground_page.dart';
import 'package:learn_flutter/features/presentation/pages/video_lesson_page/video_lesson_page.dart';
import 'package:learn_flutter/main.dart';

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
            return const AppLoadingWidget.fullScreen();
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
            final examples = state.programs
                .expand(
                  (program) =>
                      program.programDetails ?? const <ProgramDetailEntity>[],
                )
                .toList()
              ..sort(_compareExamplesByOrder);

            if (examples.isEmpty) {
              return const Center(
                child: Text(
                  'No examples available',
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
                itemCount: examples.length,
                itemBuilder: (context, index) {
                  return _buildExampleCard(context, examples[index]);
                },
              ),
            );
          }
          return const AppLoadingWidget.fullScreen();
        },
      ),
    );
  }

  int _compareExamplesByOrder(
    ProgramDetailEntity a,
    ProgramDetailEntity b,
  ) {
    final aOrder = _extractOrderNumber(a.title);
    final bOrder = _extractOrderNumber(b.title);

    if (aOrder != null && bOrder != null) {
      final orderCompare = aOrder.compareTo(bOrder);
      if (orderCompare != 0) {
        return orderCompare;
      }
    } else if (aOrder != null) {
      return -1;
    } else if (bOrder != null) {
      return 1;
    }

    return (a.title ?? '').compareTo(b.title ?? '');
  }

  int? _extractOrderNumber(String? title) {
    if (title == null || title.isEmpty) {
      return null;
    }

    final match = RegExp(r'\d+').firstMatch(title);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  Widget _buildExampleCard(BuildContext context, ProgramDetailEntity detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await ProgramProgressUtils.markExplored(
            getIt.get(),
            detail.id,
          );

          if (!context.mounted) return;

          if (detail.hasVideo) {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => VideoLessonPage(
                  title: detail.title ?? 'Video',
                  source: detail.videoUrl!.trim(),
                ),
              ),
            );
          } else {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => DartPlaygroundPage(
                  title: detail.title,
                  initialCode: detail.content?.trim() ?? '',
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: detail.hasVideo
                      ? Colors.deepPurple.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  detail.hasVideo ? Icons.ondemand_video : Icons.play_arrow,
                  size: 24,
                  color: detail.hasVideo
                      ? Colors.deepPurple.shade600
                      : Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.title ?? 'Untitled Example',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.hasVideo
                          ? 'Chạm để xem video bài học'
                          : 'Chạm để mở editor và chạy thử code',
                      style: TextStyle(
                        fontSize: 12,
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
