import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.purpleAccent),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const VoiceChatScreen(),
    );
  }
}

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with SingleTickerProviderStateMixin {
  Room? _room;
  bool joined = false;
  bool micEnabled = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  Future<String> getToken() async {
    final res = await http.get(
     Uri.parse("http://192.168.1.10:3000/getToken?identity=flutter-user&room=test-room")

    );
    final data = jsonDecode(res.body);
    return data["token"];
  }

  Future<void> joinRoom() async {
    await Permission.microphone.request();

    final token = await getToken();
    final room = Room();

    final listener = room.createListener();

    await room.connect(
      "wss://aivoiceagent-m0uqw42a.livekit.cloud",
      token,
    );

    await room.localParticipant?.setMicrophoneEnabled(micEnabled);

    listener.on<RoomEvent>((event) {
      if (event is ParticipantConnectedEvent) {
        debugPrint("👤 Participant joined: ${event.participant.identity}");
      }
      if (event is TrackSubscribedEvent) {
        debugPrint("🎧 Subscribed to track: ${event.publication.name}");
      }
    });

    setState(() {
      _room = room;
      joined = true;
    });
  }

  void toggleMic() async {
    if (_room?.localParticipant != null) {
      micEnabled = !micEnabled;
      await _room!.localParticipant!.setMicrophoneEnabled(micEnabled);
      setState(() {});
    }
  }

  void leaveRoom() {
    _room?.disconnect();
    setState(() {
      joined = false;
      _room = null;
      micEnabled = true;
    });
  }

  @override
  void dispose() {
    _room?.disconnect();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(String gender) {
    // Male/Female avatar based on gender
    return ScaleTransition(
      scale: _pulseController,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(
          gender == "male" ? Icons.male : Icons.female,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _participantList() {
    // Dummy participants for demo
    final participants = [
      {"name": "Alice", "gender": "female"},
      {"name": "Bob", "gender": "male"},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: participants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final p = participants[index];
          return Column(
            children: [
              _buildAvatar(p["gender"]!),
              const SizedBox(height: 8),
              Text(p["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🎙️ AI Voice Agent"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: joined
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _participantList(),
                  const SizedBox(height: 30),
                  Icon(
                    micEnabled ? Icons.mic : Icons.mic_off,
                    size: 80,
                    color: micEnabled ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    micEnabled ? "Microphone On" : "Microphone Off",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: toggleMic,
                    icon: Icon(micEnabled ? Icons.mic_off : Icons.mic),
                    label: Text(micEnabled ? "Mute" : "Unmute"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: leaveRoom,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text("Leave Room"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: joinRoom,
                icon: const Icon(Icons.meeting_room),
                label: const Text("Join Room"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
      ),
    );
  }
}
