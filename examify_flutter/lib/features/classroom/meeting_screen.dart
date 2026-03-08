import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/auth_provider.dart';

import '../../shared/providers/classroom_provider.dart';

class MeetingScreen extends ConsumerStatefulWidget {
  final String channelName;
  final String? classroomId;
  const MeetingScreen({super.key, required this.channelName, this.classroomId});

  @override
  ConsumerState<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends ConsumerState<MeetingScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isCameraOn = true;
  bool _isMicOn = true;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: "77607775798e4d8fb87a933f4a331189", // Temporary testing ID
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("remote user $remoteUid left channel");
              setState(() {
                _remoteUid = null;
              });
            },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
            '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token',
          );
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: '', // No token for testing
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _toggleCamera() {
    setState(() => _isCameraOn = !_isCameraOn);
    _engine.enableLocalVideo(_isCameraOn);
  }

  void _toggleMic() {
    setState(() => _isMicOn = !_isMicOn);
    _engine.enableLocalAudio(_isMicOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meeting: ${widget.channelName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () {
              final user = ref.read(authProvider).user;
              if (user?.role.name == 'teacher' && widget.classroomId != null) {
                // Turn off meeting state when host leaves
                ClassroomActions(
                  ref,
                ).toggleMeetingState(int.parse(widget.classroomId!), false);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 150,
              height: 200,
              child: Center(
                child: _localUserJoined
                    ? (_isCameraOn
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: _engine,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : _buildInitialCircle(
                              ref.watch(authProvider).user?.name ?? 'Me',
                            ))
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlCircle(
                    icon: _isMicOn ? Icons.mic : Icons.mic_off,
                    onPressed: _toggleMic,
                    isOn: _isMicOn,
                  ),
                  const SizedBox(width: 20),
                  _buildControlCircle(
                    icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                    onPressed: _toggleCamera,
                    isOn: _isCameraOn,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialCircle(String name) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: CircleAvatar(
          radius: 30,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 24),
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? Colors.white24 : Colors.red,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Text(
        'Waiting for others to join...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      );
    }
  }
}
