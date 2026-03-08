import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'stream_tab.dart';
import 'assessments_tab.dart';
import 'people_tab.dart';
import '../teacher_essentials/presentation/gradebook_screen.dart';
import '../teacher_essentials/presentation/bulk_upload_screen.dart';
import '../../../shared/providers/auth_provider.dart';

class ClassroomDetailScreen extends ConsumerWidget {
  final String id;
  const ClassroomDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role.name == 'teacher';

    return DefaultTabController(
      length: isTeacher ? 5 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Classroom'),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              onPressed: () => context.push('/classroom/$id/meet-prep'),
            ),
            IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
          ],
          bottom: TabBar(
            isScrollable: isTeacher,
            tabs: [
              const Tab(text: 'Stream'),
              const Tab(text: 'Classwork'),
              const Tab(text: 'People'),
              if (isTeacher) ...[
                const Tab(text: 'Gradebook'),
                const Tab(text: 'Import Students'),
              ],
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamTab(classroomId: id),
            AssessmentsTab(classroomId: id),
            PeopleTab(classroomId: id),
            if (isTeacher) ...[
              GradebookScreen(classroomId: int.parse(id)),
              BulkUploadScreen(classroomId: int.parse(id)),
            ],
          ],
        ),
      ),
    );
  }
}
