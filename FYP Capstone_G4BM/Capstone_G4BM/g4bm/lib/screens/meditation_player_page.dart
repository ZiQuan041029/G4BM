import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart'; // IMPORTED!

class MeditationPlayerPage extends StatefulWidget {
  final String title;
  final String author;
  final Color themeColor; // Now it takes the specific color
  final String audioPath; // Now it takes the specific audio file

  const MeditationPlayerPage({
    super.key,
    required this.title,
    required this.author,
    required this.themeColor,
    required this.audioPath,
  });

  @override
  State<MeditationPlayerPage> createState() => _MeditationPlayerPageState();
}

class _MeditationPlayerPageState extends State<MeditationPlayerPage>
    with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  bool _hasStarted = false;
  bool _isPlaying = false;
  String _breathPhase = "Inhale";

  // --- AUDIO VARIABLES ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. SETUP AUDIO LISTENERS (This perfectly syncs the timer to the file!)
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() => _totalDuration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() => _currentPosition = newPosition);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _breathingController.stop();
      });
    });

    // 2. SETUP ANIMATION
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _breathPhase = "Exhale");
        if (_isPlaying) _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _breathPhase = "Inhale");
        if (_isPlaying) _breathingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _audioPlayer.dispose(); // Always clean up the audio player!
    super.dispose();
  }

  // --- CONTROLS LOGIC ---

  void _startMeditation() async {
    setState(() {
      _hasStarted = true;
      _isPlaying = true;
    });

    // The AssetSource automatically looks inside the 'assets/' folder!
    await _audioPlayer.play(AssetSource(widget.audioPath));
    _breathingController.forward();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _breathingController.stop();
    } else {
      await _audioPlayer.resume();
      if (_breathPhase == "Inhale") {
        _breathingController.forward();
      } else {
        _breathingController.reverse();
      }
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Helper to format Duration into MM:SS
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // Math to figure out how much time is left in the song
    Duration timeRemaining = _totalDuration - _currentPosition;
    // Prevent negative numbers right at the end of the track
    if (timeRemaining.isNegative) timeRemaining = Duration.zero;

    // We now use the themeColor passed from the previous page!
    final bgColor = widget.themeColor;

    // We make the inner circle a slightly darker version of the theme color
    final innerCircleColor = Colors.black.withOpacity(0.2);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // Stop audio if they press the back button
            _audioPlayer.stop();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- THE BREATHING CIRCLES ---
            SizedBox(
              height: 350,
              width: 350,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _hasStarted ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Center(
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: _hasStarted ? null : _startMeditation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: innerCircleColor,
                      ),
                      child: Center(
                        child: Text(
                          _hasStarted ? _breathPhase : "Start",
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // --- DYNAMIC BOTTOM SECTION ---
            if (!_hasStarted)
              Text(
                "By ${widget.author}",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Column(
                children: [
                  Text(
                    // Shows the remaining time formatted beautifully
                    _formatTime(timeRemaining),
                    style: GoogleFonts.darumadropOne(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: bgColor,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
