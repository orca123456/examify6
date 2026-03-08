import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../models/classroom.dart';
import '../models/announcement.dart';
import '../models/user.dart';
import 'auth_provider.dart';

// Use Simple Providers until Riverpod 3.0 Notifier syntax is confirmed
// FutureProvider is safest for read-only / basic fetching

// Classrooms List
final classroomsProvider = FutureProvider<List<Classroom>>((ref) async {
  // Watch auth state to ensure we re-fetch when user changes
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return [];

  final response = await ref.read(apiClientProvider).get('/classrooms');
  final List<dynamic> data = response.data;
  return data.map((json) => Classroom.fromJson(json)).toList();
});

// Single Classroom Detail
final classroomDetailProvider = FutureProvider.family<Classroom, String>((
  ref,
  id,
) async {
  ref.watch(authProvider);
  final response = await ref.read(apiClientProvider).get('/classrooms/$id');
  return Classroom.fromJson(response.data);
});

// Classroom Students
final classroomStudentsProvider = FutureProvider.family<List<User>, String>((
  ref,
  id,
) async {
  ref.watch(authProvider);
  final response = await ref
      .read(apiClientProvider)
      .get('/classrooms/$id/students');
  final List<dynamic> data = response.data;
  return data.map((json) => User.fromJson(json)).toList();
});

// Announcements
final announcementsProvider = FutureProvider.family<List<Announcement>, String>(
  (ref, id) async {
    ref.watch(authProvider);
    final response = await ref
        .read(apiClientProvider)
        .get('/classrooms/$id/announcements');
    final List<dynamic> data = response.data;
    return data.map((json) => Announcement.fromJson(json)).toList();
  },
);

// For mutations (Create/Update/Delete), we'll define a simple Actions class or keep them in the UI with direct API calls for now
// to avoid syntax errors with Notifier in this environment.
class ClassroomActions {
  final WidgetRef ref;
  ClassroomActions(this.ref);

  Future<void> createClassroom(String name, String? description) async {
    await ref
        .read(apiClientProvider)
        .post('/classrooms', data: {'name': name, 'description': description});
    ref.invalidate(classroomsProvider);
  }

  Future<void> joinClassroom(String joinCode) async {
    await ref
        .read(apiClientProvider)
        .post('/join', data: {'join_code': joinCode});
    ref.invalidate(classroomsProvider);
  }

  Future<void> updateClassroom(int id, String name, String? description) async {
    await ref
        .read(apiClientProvider)
        .patch(
          '/classrooms/$id',
          data: {'name': name, 'description': description},
        );
    ref.invalidate(classroomsProvider);
    // Also invalidate detail if needed
  }

  Future<void> deleteClassroom(int id) async {
    await ref.read(apiClientProvider).delete('/classrooms/$id');
    ref.invalidate(classroomsProvider);
  }

  Future<void> toggleMeetingState(int id, bool isActive) async {
    await ref
        .read(apiClientProvider)
        .patch(
          '/classrooms/$id/meeting',
          data: {'is_meeting_active': isActive},
        );
    ref.invalidate(classroomsProvider);
    ref.invalidate(classroomDetailProvider(id.toString()));
  }
}

class AnnouncementActions {
  final WidgetRef ref;
  final String classroomId;
  AnnouncementActions(this.ref, this.classroomId);

  Future<void> create(String title, String body) async {
    await ref
        .read(apiClientProvider)
        .post(
          '/classrooms/$classroomId/announcements',
          data: {'title': title, 'body': body},
        );
    ref.invalidate(announcementsProvider(classroomId));
  }

  Future<void> update(int id, String title, String body) async {
    await ref
        .read(apiClientProvider)
        .patch('/announcements/$id', data: {'title': title, 'body': body});
    ref.invalidate(announcementsProvider(classroomId));
  }

  Future<void> delete(int id) async {
    await ref.read(apiClientProvider).delete('/announcements/$id');
    ref.invalidate(announcementsProvider(classroomId));
  }
}
