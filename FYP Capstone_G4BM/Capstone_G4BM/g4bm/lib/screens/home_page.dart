import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:g4bm/main.dart';
import 'dart:io';
import 'schedule_page.dart';
import 'progress_dashboard_page.dart';
import 'ai_chat_page.dart';
import 'my_family_page.dart';
import 'profile_page.dart';
import 'community_page.dart';
import 'reward_page.dart';

class HomePage extends StatefulWidget {
  final bool showSuccessDialog;
  final String? userMood; // Received from Mood Page

  const HomePage({super.key, this.showSuccessDialog = false, this.userMood});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasShownDialog = false;
  @override
  void initState() {
    super.initState();
    if (widget.showSuccessDialog && !_hasShownDialog) {
      _hasShownDialog = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
      });
    }
  }

  // Triggers the exact same Add Sheet from the Home Page!
  void _showAddFamilySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FamilyMemberFormSheet(
        onSave: (newMember) {
          context.read<MyAppState>().saveFamilyMember(newMember);
        },
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text(
                "Entry Successful",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Your Mood & Routine has been added.",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    var todaysEntries = appState.getEntriesForDate(DateTime.now());
    var todayMoods = todaysEntries.where((e) => e['type'] == 'mood').toList();
    var dailyReminders = todaysEntries
        .where((e) => e['reminder'] == true)
        .toList();
    List<Map<String, dynamic>> familyReminders = [];

    String displayMood = 'Others';
    if (todayMoods.isNotEmpty) {
      displayMood = todayMoods.last['label'] ?? 'Others';
    }

    List<Map<String, dynamic>> persistentReminders = [];

    // family reminders (with 24-hour logic)

    for (var member in appState.familyMembers) {
      List<dynamic> memberReminders = member['reminders'] ?? [];
      for (var r in memberReminders) {
        familyReminders.add({
          'isPersistent':
              true, // Helps the UI distinguish between Tasks and Family
          'memberName': member['name'],
          'title':
              "${member['name']}: ${r['title']}", // Formats text for the tiny card
          'originalTitle': r['title'], // Used for the toggle function
          'isDone': r['isDone'] ?? false,
          'memberId': member['id'] ?? member['_id'],
        });
      }
    }

    var allReminders = [
      ...dailyReminders,
      ...persistentReminders,
      ...familyReminders,
    ];

    final brownColor = const Color(0xFF5D4037);
    final cardBgColor = const Color(0xFF4E342E);
    final creamBg = const Color(0xFFEBE5DE);
    final innerCircleColor = const Color(0xFF917861);

    return Scaffold(
      backgroundColor: creamBg,

      // --- 1. APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Menu Button (Opens Drawer)
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 30),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // Title
        title: Text(
          'G4BM',
          style: GoogleFonts.darumadropOne(color: Colors.black, fontSize: 28),
        ),
        centerTitle: false,
        // Search Icon
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 30),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),

      // --- 2. DRAWER (MENU BAR) ---
      drawer: _buildDrawer(context),

      // --- 3. BODY CONTENT ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // TOP SECTION: Progress Ring + Reminder
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. Weekly Progress Ring
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProgressDashboardPage(),
                      ),
                    ),
                    child: SizedBox(
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. White Background Ring
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 18,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),

                          // 2. The Inner Brown Circle
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: innerCircleColor,
                              shape: BoxShape.circle,
                            ),
                          ),

                          // 3. Progress Value Ring (Dark Brown)
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: appState.getTimeframeProgress('This Week'),
                              strokeWidth: 18,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                brownColor,
                              ),
                            ),
                          ),

                          // 4. Text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Week 1",
                                style: GoogleFonts.darumadropOne(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                "Check-In for today",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // B. Reminder Card
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 180,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reminder",
                          style: GoogleFonts.darumadropOne(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Expanded(
                          child: allReminders.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No reminders.",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: allReminders.length,
                                  itemBuilder: (context, index) {
                                    final item = allReminders[index];

                                    bool isFamily =
                                        item['isPersistent'] == true;
                                    bool isDone = isFamily
                                        ? (item['isDone'] ?? false)
                                        : (item['done'] ?? false);

                                    String displayText = isFamily
                                        ? item['title'] // e.g., "Maya: Breast Milk Intake"
                                        : "${item['time'] ?? ''} ${item['label'] ?? ''}"
                                              .trim();
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (isFamily) {
                                                // Calls the function we added to main.dart earlier
                                                context
                                                    .read<MyAppState>()
                                                    .toggleFamilyReminder(
                                                      item['memberId'],
                                                      item['originalTitle'],
                                                    );
                                              } else {
                                                // Standard schedule task toggle
                                                item['done'] = !isDone;
                                                context
                                                    .read<MyAppState>()
                                                    .addOrUpdateEntry(item);
                                              }
                                            },
                                            child: Icon(
                                              isDone
                                                  ? Icons.check_circle
                                                  : Icons
                                                        .radio_button_unchecked,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // MIDDLE SECTION: Today's Mood + AI Chat
            Row(
              children: [
                // C. Today's Mood
                Expanded(
                  flex: 4,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchedulePage()),
                    ),
                    child: Container(
                      height: 180,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8AD96),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          // 1. The Bear Icon (Left Aligned)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              _getMoodImage(displayMood),
                              height: 60,
                            ),
                          ),

                          // 2. The Text (Top Left)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Text(
                              "Today's",
                              style: GoogleFonts.darumadropOne(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),

                          // 3. Bottom Text
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Text(
                              "Tap to check how you are doing today.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // D. AI Chatbot
                Expanded(
                  flex: 5,
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
                      height: 180,
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
                                    height: 1,
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Image.asset(
                              'assets/G4BM_logo.png',
                              width: 70,
                              height: 70,
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

            const SizedBox(height: 30),

            // BOTTOM SECTION: My Family
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyFamilyPage(initialFilter: 'All'),
                ), // Black Area -> 'All'
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3E3E), // Dark container
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My family",
                      style: GoogleFonts.darumadropOne(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // DYNAMICALLY GENERATE THE FAMILY AVATARS!
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: appState.familyMembers.map((member) {
                                return GestureDetector(
                                  onTap: () {
                                    // Avatar Tap -> Specific Member!
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MyFamilyPage(
                                          initialFilter: member['name'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 15.0),
                                    child: _buildDynamicFamilyAvatar(member),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // THE ADD BUTTON
                        GestureDetector(
                          onTap: () => _showAddFamilySheet(
                            context,
                          ), // + Tap -> Pop Up Add Sheet!
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4E342E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black45, blurRadius: 5),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  // Drawer (Menu Bar)
  // 1. Updated Helper Function (Make sure this is outside _buildDrawer)
  Widget _buildMenuItem(String title, TextStyle style, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      title: Text(title, style: style),
      onTap: onTap,
    );
  }

  // 2. Functional Drawer
  Widget _buildDrawer(BuildContext context) {
    final menuStyle = GoogleFonts.darumadropOne(
      fontSize: 18,
      color: Colors.black,
    );

    return Drawer(
      backgroundColor: const Color(0xFFEBE5DE),
      child: SafeArea(
        // 1. USE LISTVIEW INSTEAD OF COLUMN
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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

            // Now all these items can be scrolled if the screen is too short!
            _buildMenuItem("Home", menuStyle, () => Navigator.pop(context)),
            _buildMenuItem("Profile", menuStyle, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }),
            _buildMenuItem("Explore", menuStyle, () => Navigator.pop(context)),
            _buildMenuItem("Community", menuStyle, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommunityPage()),
              );
            }),
            _buildMenuItem(
              "AI-Therapist",
              menuStyle,
              () => Navigator.pop(context),
            ),
            _buildMenuItem("Progress Dashboard", menuStyle, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgressDashboardPage(),
                ),
              );
            }),
            _buildMenuItem("My Family", menuStyle, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyFamilyPage()),
              );
            }),
            _buildMenuItem(
              "Meditation",
              menuStyle,
              () => Navigator.pop(context),
            ),
            _buildMenuItem("Reward", menuStyle, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RewardPage()),
              );
            }),
            _buildMenuItem("Help", menuStyle, () => Navigator.pop(context)),

            // Add a little extra space at the bottom for breathing room
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getMoodImage(String? moodLabel) {
    switch (moodLabel) {
      case 'Neutral':
        return 'assets/emotions/Neutral.png';
      case 'Happy':
        return 'assets/emotions/Happy.png';
      case 'Sad':
        return 'assets/emotions/Sad.png';
      case 'Annoyed':
        return 'assets/emotions/Annoyed.png';
      case 'Mad':
        return 'assets/emotions/Mad.png';
      case 'Worried':
        return 'assets/emotions/Worried.png';
      case 'Overwhelm':
        return 'assets/emotions/Overwhelm.png';
      case 'Tired':
        return 'assets/emotions/Tired.png';
      case 'Sick':
        return 'assets/emotions/Sick.png';
      case 'Stressed':
        return 'assets/emotions/Stressed.png';
      case 'Frustrated':
        return 'assets/emotions/Frustrated.png';
      default:
        return 'assets/emotions/Others.png';
    }
  }
}

Widget _buildDynamicFamilyAvatar(Map<String, dynamic> member) {
  String imagePath = member['image'] ?? 'assets/default_user_pp.png';
  bool isFile = imagePath.startsWith('/');

  return Column(
    children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          image: DecorationImage(
            // Changed java.io.File to just File
            image: isFile
                ? FileImage(File(imagePath)) as ImageProvider
                : AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        member['name'],
        style: const TextStyle(color: Colors.white, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
