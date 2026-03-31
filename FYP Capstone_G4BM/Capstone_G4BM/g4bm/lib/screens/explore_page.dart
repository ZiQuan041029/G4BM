import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart'; // Ensure this points to your actual main.dart
import 'schedule_page.dart';
import 'ai_chat_page.dart';
import 'meditation_page.dart';
import 'reward_page.dart';
import 'resource_library_page.dart';
import 'article_reading_page.dart'; // If you made the placeholder a separate file

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // Colors based on your design
  final Color creamBg = const Color(0xFFEBE5DE);
  final Color brownColor = const Color(0xFF5D4037);

  // Me-Time Logic
  late Map<String, dynamic> _currentMeTime;
  final List<Map<String, dynamic>> _meTimeOptions = [
    {
      'title': 'Watch a movie',
      'time': '20:00 - 22:00',
      'duration': 120,
      'icon': Icons.tv,
    },
    {
      'title': 'Read a Book',
      'time': '20:30 - 22:00',
      'duration': 90,
      'icon': Icons.menu_book,
    },
    {
      'title': 'Spa Time',
      'time': '21:00 - 22:00',
      'duration': 60,
      'icon': Icons.spa,
    },
    {
      'title': 'Listen to Podcast',
      'time': '16:00 - 17:00',
      'duration': 60,
      'icon': Icons.headphones,
    },
  ];

  @override
  void initState() {
    super.initState();
    _randomizeMeTime();
  }

  void _randomizeMeTime() {
    final random = Random();
    setState(() {
      _currentMeTime = _meTimeOptions[random.nextInt(_meTimeOptions.length)];
    });
  }

  void _addMeTimeActivity() {
    final appState = context.read<MyAppState>();
    final now = DateTime.now();

    final startTimeString = _currentMeTime['time'].split(' - ')[0];
    final parts = startTimeString.split(':');
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final newEntry = {
      'id': 'metime_${now.millisecondsSinceEpoch}',
      'fullDateTime': startDateTime,
      'time': startTimeString,
      'type': 'task',
      'label': _currentMeTime['title'],
      'end': _currentMeTime['time'].split(' - ')[1],
      'icon': _currentMeTime['icon'],
      'done': false,
      'durationMinutes': _currentMeTime['duration'],
      'reminder': true,
    };

    appState.addOrUpdateEntry(newEntry);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(
          Icons.check_circle,
          color: Color(0xFFB5C99A),
          size: 50,
        ),
        content: Text(
          "${_currentMeTime['title']} has been added to your schedule, enjoy your time, Mama!",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _randomizeMeTime();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black, size: 30),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: Text(
          'Explore',
          style: GoogleFonts.darumadropOne(color: Colors.black, fontSize: 28),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 30),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. TOP ROW
            Row(
              children: [
                Expanded(
                  child: _buildGridCard(
                    title: "My Schedule",
                    subtitle: "Manage your time with reminder",
                    bgColor: const Color(0xFFC8AD96),
                    icon: Icons.calendar_month,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchedulePage()),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AIChatPage(
                          currentUserId:
                              context.read<MyAppState>().currentUserId ?? "",
                        ),
                      ),
                    ),
                    child: Container(
                      height: 160,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 5,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Chat with",
                                  style: GoogleFonts.dmSerifDisplay(
                                    color: Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                Text(
                                  "Mama Bear.",
                                  style: GoogleFonts.darumadropOne(
                                    color: const Color(0xFF5D4037),
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Your personal AI Therapist.",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Image.asset(
                              'assets/G4BM_logo.png',
                              width: 65,
                              height: 65,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. ME-TIME BANNER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF919191),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You haven't had much \"Me-Time\" lately.",
                    style: GoogleFonts.darumadropOne(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(
                        _currentMeTime['icon'],
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentMeTime['time'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _currentMeTime['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.fact_check,
                        color: Colors.white54,
                        size: 60,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _addMeTimeActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB5C99A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. MIDDLE ROW
            Row(
              children: [
                Expanded(
                  child: _buildGridCard(
                    title: "Meditation",
                    subtitle: "Guided Exercises to calm you down",
                    bgColor: Colors.white,
                    icon: Icons.self_improvement,
                    iconColor: Colors.green[300]!,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MeditationPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildGridCard(
                    title: "Reward",
                    subtitle: "Daily check-in streaks with rewards",
                    bgColor: const Color(0xFFAB9E92),
                    imageAsset: 'assets/BZCoin.png',
                    iconColor: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RewardPage()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. ARTICLES & BLOGS (Cleanly calls the perfectly functioning helper)
            _buildArticlesAndBlogsSection(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required Color bgColor,
    required VoidCallback onTap,
    IconData? icon,
    String? imageAsset,
    bool isTitleSerif = false,
    Color iconColor = const Color(0xFF5D4037),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: isTitleSerif
                        ? GoogleFonts.dmSerifDisplay(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          )
                        : GoogleFonts.darumadropOne(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: imageAsset != null
                  ? Image.asset(
                      imageAsset,
                      width: 65,
                      height: 65,
                      fit: BoxFit.contain,
                    )
                  : Icon(icon, color: iconColor, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesAndBlogsSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResourceLibraryPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF3B3B3B),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Articles & Blogs",
              style: GoogleFonts.darumadropOne(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 160, // Fixed height to contain the 160 cards
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildArticleCard(
                    context,
                    "Always feel\nOverwhelming?",
                    "An article about how to fix your brain.",
                    const Color(0xFFD4DAE0),
                    "https://www.verywellmind.com/feeling-overwhelmed-symptoms-causes-and-coping-5425548",
                  ),
                  const SizedBox(width: 15),
                  _buildArticleCard(
                    context,
                    "Mutual Impact of\nRelationship...",
                    "How it affects your mental health.",
                    const Color(0xFFE6C9C9),
                    "https://sweetinstitute.com/the-impact-of-relationships-on-emotional-well-being-mental-health-and-life-satisfaction/",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(
    BuildContext context,
    String title,
    String description,
    Color bgColor,
    String url,
  ) {
    return GestureDetector(
      onTap: () {
        // Ensure SimpleArticleReadingPage exists in article_reading_page.dart!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SimpleArticleReadingPage(title: title, url: url),
          ),
        );
      },
      child: Container(
        width: 160, // Lock the width so it doesn't cause infinity errors
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.darumadropOne(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.black54),
            ),
            const Spacer(),
            const Center(
              child: Icon(Icons.article, color: Colors.black38, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final menuStyle = GoogleFonts.darumadropOne(
      fontSize: 18,
      color: Colors.black,
    );
    return Drawer(
      backgroundColor: creamBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu),
                  Text(
                    "G4BM",
                    style: GoogleFonts.darumadropOne(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.search),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            _buildMenuItem("Home", menuStyle),
            _buildMenuItem("Profile", menuStyle),
            _buildMenuItem("Explore", menuStyle, highlight: true),
            _buildMenuItem("Community", menuStyle),
            _buildMenuItem("AI-Therapist", menuStyle),
            _buildMenuItem("Progress Dashboard", menuStyle),
            _buildMenuItem("My Family", menuStyle),
            _buildMenuItem("Meditation", menuStyle),
            _buildMenuItem("Reward", menuStyle),
            _buildMenuItem("Help", menuStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    TextStyle style, {
    bool highlight = false,
  }) {
    return Container(
      color: highlight ? Colors.black12 : Colors.transparent,
      child: ListTile(
        title: Text(title, style: style.copyWith(fontWeight: FontWeight.bold)),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
