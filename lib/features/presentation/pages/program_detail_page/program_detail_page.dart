import 'package:flutter/material.dart';
import 'package:learn_flutter/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_flutter/features/presentation/pages/dart_playground_page/dart_playground_page.dart';
import 'package:learn_flutter/features/presentation/pages/video_lesson_page/video_lesson_page.dart';

class ProgramDetailPage extends StatelessWidget {
  final ProgramEntity program;

  const ProgramDetailPage({
    Key? key,
    required this.program,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(program.name ?? 'Program Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: program.programDetails?.isEmpty == true
          ? const Center(
              child: Text(
                'No examples available',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: program.programDetails?.length ?? 0,
              itemBuilder: (context, index) {
                final detail = program.programDetails![index];
                return _buildExampleCard(context, detail);
              },
            ),
    );
  }

  Widget _buildExampleCard(BuildContext context, ProgramDetailEntity detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
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
