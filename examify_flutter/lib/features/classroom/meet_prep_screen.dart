import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/auth_provider.dart';

import '../../shared/providers/classroom_provider.dart';

class MeetPrepScreen extends ConsumerStatefulWidget {
  final String classroomId;
  const MeetPrepScreen({super.key, required this.classroomId});

  @override
  ConsumerState<MeetPrepScreen> createState() => _MeetPrepScreenState();
}

class _MeetPrepScreenState extends ConsumerState<MeetPrepScreen> {
  CameraController? _controller;
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found';
          _isInitializing = false;
        });
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Camera permission denied or error occurred';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleCamera() async {
    setState(() => _isCameraOn = !_isCameraOn);
    if (_isCameraOn) {
      await _controller?.resumePreview();
    } else {
      await _controller?.pausePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.role.name == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
              tooltip: 'Host controls',
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Camera Preview Box
              // ... (container code remains the same as before) ...
              Container(
                width: 640,
                height: 360,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isInitializing)
                      const CircularProgressIndicator()
                    else if (_error != null || !_isCameraOn)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_off,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error ?? 'Camera is off',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      )
                    else if (_controller != null &&
                        _controller!.value.isInitialized)
                      CameraPreview(_controller!)
                    else
                      const Text(
                        'Initializing camera...',
                        style: TextStyle(color: Colors.white),
                      ),

                    Positioned(
                      bottom: 16,
                      child: Row(
                        children: [
                          _buildControlCircle(
                            icon: _isMicOn ? Icons.mic : Icons.mic_off,
                            onPressed: () =>
                                setState(() => _isMicOn = !_isMicOn),
                            isOn: _isMicOn,
                          ),
                          const SizedBox(width: 16),
                          _buildControlCircle(
                            icon: _isCameraOn
                                ? Icons.videocam
                                : Icons.videocam_off,
                            onPressed: _toggleCamera,
                            isOn: _isCameraOn,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Ready to join?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (isTeacher) {
                        ClassroomActions(ref).toggleMeetingState(
                          int.parse(widget.classroomId),
                          true,
                        );
                      }
                      context.push(
                        '/meeting/test-channel?classroomId=${widget.classroomId}',
                      ); // Temporary hardcoded channel for testing
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(isTeacher ? 'Join now' : 'Ask to join'),
                  ),
                  const SizedBox(width: 16),
                  if (isTeacher)
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.present_to_all),
                      label: const Text('Present'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final classroomAsync = ref.watch(
                    classroomDetailProvider(widget.classroomId),
                  );
                  return classroomAsync.when(
                    data: (classroom) => Text(
                      isTeacher
                          ? 'No one else is here'
                          : '${classroom.teacher?.name ?? 'Teacher'} is in this call',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading class details'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isOn,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? Colors.white24 : Colors.redAccent,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
