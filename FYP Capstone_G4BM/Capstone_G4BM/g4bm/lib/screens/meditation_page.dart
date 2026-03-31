import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'meditation_player_page.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> {
  // 1. State for the currently selected category
  String _selectedCategory = "All";

  // 2. The categories for the top scrollable bar
  final List<String> _categories = [
    "All",
    "Mindfulness",
    "Sleep",
    "Stress reduction",
    "Anxiety reduction",
  ];

  // 3. Mock Data for the meditations
  final List<Map<String, dynamic>> _allMeditations = [
    {
      "title": "State of Meditation",
      "description": "Elm Lake",
      "duration": "3 minutes 07 seconds",
      "category": "Mindfulness",
      "color": const Color(0xFFFFD54F),
      "icon": Icons.wb_sunny_rounded,
      "audioPath": "audio/state_of_meditation.mp3",
    },
    {
      "title": "Just Breathe",
      "description": "Amber Glow",
      "duration": "3 minutes 22 seconds",
      "category": "Anxiety reduction",
      "color": const Color(0xFFFFB74D), // Orange vibe
      "icon": Icons.air,
      "audioPath": "audio/just_breathe.mp3",
    },
    {
      "title": "Snowdrop",
      "description": "Shuta Yasukochi",
      "duration": "3 minutes 30 seconds",
      "category": "Sleep",
      "color": const Color(0xFF00008B),
      "icon": Icons.nightlight_round,
      "audioPath": "audio/snowdrop.mp3",
    },
    {
      "title": "Rainy Days",
      "description": "A safe and warm place.",
      "duration": "2 minutes 39 seconds",
      "category": "Stress reduction",
      "color": const Color(0xFF42A5F5), // Blue vibe
      "icon": Icons.cloud,
      "audioPath": "audio/rainy_days.mp3",
    },
    {
      "title": "Sun and Energy",
      "description": "Ghoststrifter Official",
      "duration": "2 minutes",
      "category": "Mindfulness",
      "color": const Color(0xFF26C6DA), // Teal vibe
      "icon": Icons.wb_twilight,
      "audioPath": "audio/sun_and_energy.mp3",
    },
    {
      "title": "Ocean Breeze",
      "description": "Feel the waves.",
      "duration": "1 minutes 10 seconds",
      "category": "Stress reduction",
      "color": const Color(0xFFB7DBD6),
      "icon": Icons.waves,
      "audioPath": "audio/ocean_breeze.mp3",
    },
    {
      "title": "Inner Balance",
      "description": "Elm Lake",
      "duration": "3 minutes",
      "category": "Anxiety reduction",
      "color": const Color(0xFFF8AD9D),
      "icon": Icons.balance,
      "audioPath": "audio/inner_balance.mp3",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF5D4037);
    final creamBg = const Color(0xFFFFF9F0);

    // Filter the list based on the selected category
    List<Map<String, dynamic>> filteredMeditations = _selectedCategory == "All"
        ? _allMeditations
        : _allMeditations
              .where((item) => item['category'] == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Meditation",
          style: GoogleFonts.darumadropOne(color: Colors.black, fontSize: 28),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CATEGORY PILLS (Horizontal Scroll) ---
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black87 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // --- MEDITATION CARDS LIST ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredMeditations.length,
              itemBuilder: (context, index) {
                final item = filteredMeditations[index];
                return _buildMeditationCard(item, brownColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- INDIVIDUAL CARD WIDGET ---
  Widget _buildMeditationCard(Map<String, dynamic> item, Color themeColor) {
    // --- WRAP THE CARD IN INKWELL TO MAKE IT CLICKABLE ---
    return InkWell(
      onTap: () {
        // Navigate to the player and pass the data!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeditationPlayerPage(
              title: item['title'],
              author: item['description'],
              themeColor: item['color'], // Pass the color!
              audioPath:
                  item['audioPath'], // Using description as author based on mockup
              // You can parse the item['duration'] here later
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Image/Illustration Area
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: item['color'],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Center(
                child: Icon(
                  item['icon'],
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),

            // 2. Text Content Area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item['description'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Bottom Row: Duration & Start Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['duration'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Start",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: themeColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
