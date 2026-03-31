import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AIVoiceChatPage extends StatefulWidget {
  const AIVoiceChatPage({super.key});

  @override
  State<AIVoiceChatPage> createState() => _AIVoiceChatPageState();
}

class _AIVoiceChatPageState extends State<AIVoiceChatPage>
    with SingleTickerProviderStateMixin {
  final Color darkBg = const Color(0xFF2C2C2C);

  // State variables
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _hasResult = false;
  String _transcribedText = "";
  String _aiReply = "";
  Color _orbColor = const Color(0xFF5A75C7); // Default Blue-ish

  late Record _recorder;
  File? _audioFile;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _recorder = Record();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // --- RECORDING LOGIC ---
  void _toggleRecording() async {
    if (_hasResult || _isAnalyzing) {
      setState(() {
        _hasResult = false;
        _transcribedText = "";
        _aiReply = "";
        _orbColor = const Color(0xFF5A75C7);
      });
      return;
    }

    if (_isRecording) {
      await _stopRecordingAndSend();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/mama_bear_audio.m4a';

        // In version 4.x, configuration is passed as direct named arguments
        await _recorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc, // Standard AAC
          bitRate: 128000,
          samplingRate: 44100,
        );

        setState(() {
          _isRecording = true;
          _transcribedText = "Listening...";
        });
        _pulseController.repeat(reverse: true);
      }
    } catch (e) {
      debugPrint("Start recording error: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    _pulseController.stop();
    final path = await _recorder.stop();

    if (path == null) return;

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
      _transcribedText = "Analyzing your tone...";
    });

    _audioFile = File(path);
    await _sendVoiceToAI("mom_user_123");
  }

  Future<void> _sendVoiceToAI(String userId) async {
    if (_audioFile == null) return;

    try {
      final uri = Uri.parse('http://localhost:5001/voice-chat/$userId');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          _audioFile!.path,
          contentType: MediaType('audio', 'm4a'),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _transcribedText = data['transcribedMessage'] ?? "";
          _aiReply = data['reply'] ?? "";
          _isAnalyzing = false;
          _hasResult = true;

          if (data['emotion'] == 'stressed') {
            _orbColor = Colors.orangeAccent;
            _showStressedSnackbar();
          } else {
            _orbColor = const Color(0xFFBDE076); // Calm Green
          }
        });
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _transcribedText = "Connection lost. Is the server running?";
      });
    } finally {
      if (_audioFile != null && await _audioFile!.exists()) {
        await _audioFile!.delete();
      }
    }
  }

  void _showStressedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "I can hear the stress in your voice, mama. I'm right here.",
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelEverything() {
    _recorder.stop();
    _pulseController.stop();
    setState(() {
      _isRecording = false;
      _isAnalyzing = false;
      _hasResult = false;
      _transcribedText = "";
      _aiReply = "";
      _orbColor = const Color(0xFF5A75C7);
    });
  }

  // --- HISTORY POP-UP ---
  void _showHistoryPopUp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Color(0xFFEBE5DE),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Session History",
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: (_transcribedText.isEmpty && !_hasResult)
                      ? Text(
                          "No conversation recorded yet.",
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _historyBubble(
                              "You asked:",
                              _transcribedText,
                              const Color(0xFFBDE076),
                            ),
                            const SizedBox(height: 20),
                            if (_hasResult)
                              _historyBubble(
                                "Mama Bear replied:",
                                _aiReply,
                                Colors.white,
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyBubble(String label, String text, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _isAnalyzing
                  ? "Analyzing Tone..."
                  : (_isRecording ? "I'm listening" : "How are you feeling?"),
              style: GoogleFonts.darumadropOne(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: _hasResult ? _buildResultView() : _buildListeningView(),
              ),
            ),
            _buildBottomControls(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRecording ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_orbColor.withOpacity(0.8), _orbColor, darkBg],
                    stops: const [0.2, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _orbColor.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 50),
        Text(
          _transcribedText,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _aiReply,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "“ $_transcribedText ”",
              style: const TextStyle(
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleBtn(Icons.history, _showHistoryPopUp, 50),
          _circleBtn(
            _isRecording
                ? Icons.stop
                : (_hasResult ? Icons.refresh : Icons.mic),
            _toggleRecording,
            80,
            isMain: true,
          ),
          _circleBtn(Icons.close, _cancelEverything, 50),
        ],
      ),
    );
  }

  Widget _circleBtn(
    IconData icon,
    VoidCallback onTap,
    double size, {
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: darkBg, size: isMain ? 35 : 25),
      ),
    );
  }
}
