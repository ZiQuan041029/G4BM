import 'package:flutter/material.dart';
import 'package:g4bm/screens/community_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:g4bm/main.dart';
import 'package:provider/provider.dart';

import 'reward_page.dart';
import 'mood_insights_page.dart';
import 'schedule_page.dart';

import '../services/api_service.dart';
import '../models/mood_entry.dart';
import '../models/sleep_entry.dart';

class ProgressDashboardPage extends StatefulWidget {
  const ProgressDashboardPage({super.key});

  @override
  State<ProgressDashboardPage> createState() => _ProgressDashboardPageState();
}

class _ProgressDashboardPageState extends State<ProgressDashboardPage> {
  final Color creamBg = const Color(0xFFEBE5DE);
  final Color darkBrown = const Color(0xFF4A3B32);
  final Color lightBrown = const Color(0xFFAFA296);
  final Color taupeCard = const Color(0xFFAFA296);
  final Color greenTick = const Color(0xFFB6CD7C);
  final Color orangeBar = const Color(0xFFFF8A65);
  final Color redBar = const Color(0xFFFF5252);

  String _selectedTimeline = 'Today';

  bool _isLoading = true;
  MoodEntry? _todayMood;
  SleepEntry? _todaySleep;

  @override
  void initState() {
    super.initState();
    _fetchTodayData();
  }

  Future<void> _fetchTodayData() async {
    // 1. Grab the real date!
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 2. Grab the real user ID from your app state!
    var appState = Provider.of<MyAppState>(context, listen: false);
    String? realUserId = appState.currentUserId;

    if (realUserId != null) {
      final mood = await ApiService().getTodaysMood(realUserId, todayStr);
      final sleep = await ApiService().getTodaysSleep(realUserId, todayStr);

      if (mounted) {
        setState(() {
          _todayMood = mood;
          _todaySleep = sleep;
          _isLoading = false;
        });
      }
    } else {
      // Failsafe if user isn't logged in somehow
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: creamBg,
        body: Center(child: CircularProgressIndicator(color: darkBrown)),
      );
    }

    var appState = context.watch<MyAppState>();
    var todaysEntries = appState.getEntriesForDate(DateTime.now());
    var todaysReminders = todaysEntries
        .where((entry) => entry['reminder'] == true)
        .toList();

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Progress Dashboard",
          style: GoogleFonts.darumadropOne(color: Colors.black87, fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildTimelineFilters(),
            const SizedBox(height: 25),

            // --- DYNAMIC CONTENT SWITCHER ---
            if (_selectedTimeline == 'Today')
              _buildTodayView(todaysReminders)
            else if (_selectedTimeline == 'This Week')
              _buildThisWeekView()
            else if (_selectedTimeline == 'This Month')
              _buildThisMonthView()
            else if (_selectedTimeline == 'This Year')
              _buildThisYearView(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: TODAY
  // ==========================================
  Widget _buildTodayView(List<Map<String, dynamic>> todaysReminders) {
    var appState = context.watch<MyAppState>();
    var todaysEntries = appState.getEntriesForDate(DateTime.now());
    var localMoods = todaysEntries.where((e) => e['type'] == 'mood').toList();

    bool isCheckedIn = appState.dailyProgress['hasLoggedMoodAndSleep'] ?? false;
    bool hasCompletedSchedule =
        appState.dailyProgress['hasCompletedSchedule'] ?? false;
    bool hasInteractPost =
        appState.dailyProgress['hasInteractedWithCommunity'] ?? false;

    bool alreadyClaimed = appState.alreadyClaimedToday;
    bool allTasksDone = isCheckedIn && hasCompletedSchedule && hasInteractPost;

    String todayMoodImage = 'assets/emotions/Others.png';
    bool hasMoodEntry = false;

    if (localMoods.isNotEmpty) {
      todayMoodImage =
          localMoods.first['icon']; // Grab the PNG of the first mood logged!
      hasMoodEntry = true;
    } else if (_todayMood != null) {
      todayMoodImage =
          'assets/emotions/${_todayMood!.emotionalLabel}.png'; // API fallback
      hasMoodEntry = true;
    }

    return Column(
      children: [
        _buildCheckInStatus(isCheckedIn),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildDailyTasksCard(
                    isCheckedIn,
                    hasCompletedSchedule,
                    hasInteractPost,
                    allTasksDone,
                    alreadyClaimed,
                  ),
                  const SizedBox(height: 15),
                  _buildMoodAnalyticsCard(),
                  const SizedBox(height: 15),
                  _buildReminderCard(todaysReminders),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                children: [
                  _buildRewardCard(appState.bzPoints),
                  const SizedBox(height: 15),
                  _buildTodaysCard(hasMoodEntry, todayMoodImage),
                  const SizedBox(height: 15),
                  _buildCommunityCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: THIS WEEK
  // ==========================================
  Widget _buildThisWeekView() {
    var appState = context.watch<MyAppState>();
    var realActivities = appState.getCompletedTasksStats('This Week');
    double progress = appState.getTimeframeProgress('This Week');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your progress this week.",
          style: GoogleFonts.darumadropOne(fontSize: 26, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        _buildWeeklyCalendarCard(appState),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildSharedProgressCircle("Week 1", progress)),
            const SizedBox(width: 15),
            Expanded(child: _buildSharedMoodButton()),
          ],
        ),
        const SizedBox(height: 20),

        // Use the REAL activities list!
        if (realActivities.isEmpty)
          const Center(child: Text("Complete some tasks to see your stats!"))
        else
          _buildSharedTopActivityCard(
            "Top Activity this week.",
            realActivities,
          ),
      ],
    );
  }

  // ==========================================
  // VIEW 3: THIS MONTH
  // ==========================================
  Widget _buildThisMonthView() {
    var appState = context.watch<MyAppState>();
    var realActivities = appState.getCompletedTasksStats('This Month');
    double progress = appState.getTimeframeProgress('This Month');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your progress this month.",
          style: GoogleFonts.darumadropOne(fontSize: 26, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        _buildMonthlyCalendarCard(appState),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildSharedProgressCircle(
                DateFormat('MMMM').format(DateTime.now()),
                progress,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: _buildSharedMoodButton()),
          ],
        ),
        const SizedBox(height: 20),
        if (realActivities.isEmpty)
          const Center(child: Text("Complete some tasks to see your stats!"))
        else
          _buildSharedTopActivityCard(
            "Top Activity this month.",
            realActivities,
          ),
      ],
    );
  }

  // ==========================================
  // VIEW 4: THIS YEAR
  // ==========================================
  Widget _buildThisYearView() {
    var appState = context.watch<MyAppState>();
    var realActivities = appState.getCompletedTasksStats('This Year');
    double progress = appState.getTimeframeProgress('This Year');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your progress this year.",
          style: GoogleFonts.darumadropOne(fontSize: 26, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        _buildYearlyCalendarCard(appState),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildSharedProgressCircle(
                DateTime.now().year.toString(),
                progress,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: _buildSharedMoodButton()),
          ],
        ),
        const SizedBox(height: 20),
        if (realActivities.isEmpty)
          const Center(child: Text("Complete some tasks to see your stats!"))
        else
          _buildSharedTopActivityCard(
            "Top Activity this year.",
            realActivities,
          ),
      ],
    );
  }

  // ==========================================
  // REUSABLE UI COMPONENTS (Week/Month/Year)
  // ==========================================

  // ---> LIVE WEEKLY CALENDAR <---
  Widget _buildWeeklyCalendarCard(MyAppState appState) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    List<String> dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: taupeCard,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM').format(startOfWeek), // LIVE MONTH TEXT
            style: GoogleFonts.darumadropOne(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              DateTime date = startOfWeek.add(Duration(days: index));
              double progress = appState.getDayProgress(
                date,
              ); // GRABS LIVE DB DATA!
              bool isToday =
                  date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day;
              return _buildProgressRing(
                dayLabels[index],
                "${date.day}",
                progress,
                isToday,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---> LIVE MONTHLY CALENDAR <---
  Widget _buildMonthlyCalendarCard(MyAppState appState) {
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    ).day; // Magic code for days in month

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: taupeCard,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM').format(now), // LIVE MONTH TEXT
            style: GoogleFonts.darumadropOne(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              DateTime date = DateTime(now.year, now.month, index + 1);
              double progress = appState.getDayProgress(
                date,
              ); // GRABS LIVE DB DATA!
              bool isToday = date.day == now.day;
              return _buildProgressRing("", "${index + 1}", progress, isToday);
            },
          ),
        ],
      ),
    );
  }

  // ---> LIVE YEARLY CALENDAR <---
  Widget _buildYearlyCalendarCard(MyAppState appState) {
    DateTime now = DateTime.now();
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: taupeCard,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${now.year}", // LIVE YEAR TEXT
            style: GoogleFonts.darumadropOne(fontSize: 28, color: Colors.white),
          ),
          const SizedBox(height: 30),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 1,
              childAspectRatio: 1,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              double progress = appState.getMonthProgress(
                now.year,
                index + 1,
              ); // GRABS LIVE DB DATA!
              bool isCurrentMonth = index + 1 == now.month;
              return _buildProgressRing(
                "",
                months[index],
                progress,
                isCurrentMonth,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(
    String topLabel,
    String centerLabel,
    double progress,
    bool isCurrent,
  ) {
    return Column(
      children: [
        if (topLabel.isNotEmpty) ...[
          Text(
            topLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 4,
                color: Colors.white.withOpacity(0.3),
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                color: progress == 0 ? Colors.transparent : greenTick,
                backgroundColor: Colors.transparent,
              ),
              Center(
                child: Text(
                  centerLabel,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white70,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: topLabel.isEmpty ? 14 : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. Shared Widgets (Circle, Mood, Top Activities) ---
  Widget _buildSharedProgressCircle(String title, double progress) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 15,
              color: taupeCard.withOpacity(0.4),
            ),
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 15,
              color: darkBrown,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: taupeCard,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Overall Activity\nProgress",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedMoodButton() {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MoodInsightsPage()),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: darkBrown,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar(60, greenTick),
                  const SizedBox(width: 4),
                  _buildBar(30, orangeBar),
                  const SizedBox(width: 4),
                  _buildBar(80, greenTick),
                  const SizedBox(width: 4),
                  _buildBar(40, greenTick),
                  const SizedBox(width: 4),
                  _buildBar(20, Colors.grey),
                  const SizedBox(width: 4),
                  _buildBar(10, Colors.grey),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "Mood Analytics",
                style: GoogleFonts.darumadropOne(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedTopActivityCard(
    String title,
    List<Map<String, dynamic>> activities,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1ED),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.darumadropOne(
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: _buildActivityRow(
                activity['title'],
                activity['time'],
                activity['icon'],
                activity['color'],
                activity['factor'],
              ),
            );
          }),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: greenTick,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 10,
                ),
              ),
              child: const Text(
                "Share",
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
    String title,
    String time,
    IconData icon,
    Color color,
    double widthFactor,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 12,
                  width: constraints.maxWidth * widthFactor,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.black87),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total time: $time",
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- EXISTING UI COMPONENTS (For 'Today' view) ---

  Widget _buildTimelineFilters() {
    final filters = ['Today', 'This Week', 'This Month', 'This Year'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedTimeline == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedTimeline = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? darkBrown : lightBrown.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckInStatus(bool isCheckedIn) {
    return Column(
      children: [
        if (isCheckedIn) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: darkBrown, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 15),
          Text(
            "Congrats!\nYou've checked in today.",
            textAlign: TextAlign.center,
            style: GoogleFonts.darumadropOne(
              fontSize: 24,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ] else ...[
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey, width: 2),
            ),
            child: const Icon(
              Icons.edit_calendar,
              color: Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Oops, no entry today yet...",
            style: GoogleFonts.darumadropOne(
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Fill in your mood and sleep schedule to check in.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildDailyTasksCard(
    bool isCheckedIn,
    bool hasCompletedSchedule,
    bool hasInteractPost,
    bool allTasksDone,
    bool alreadyClaimed,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskRow("Checked In to the App", isCheckedIn),
          const SizedBox(height: 12),
          _buildTaskRow("Complete a Schedule", hasCompletedSchedule),
          const SizedBox(height: 12),
          _buildTaskRow("Like/Comment a community post", hasInteractPost),
          const SizedBox(height: 20),
          Center(
            child: alreadyClaimed
                ? const Text(
                    "Points Claimed Today! 🎉",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFB6CD7C), // Your green tick color
                    ),
                  )
                : allTasksDone
                ? ElevatedButton(
                    onPressed: () async {
                      bool success = await context
                          .read<MyAppState>()
                          .claimPoints();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("5 BZPoints Claimed!")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Claim 5 Points",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    "Complete all tasks to\nclaim 5 BZPoints",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: darkBrown,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(String title, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? greenTick : Colors.grey[400],
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDone ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(int totalPoints) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RewardPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: lightBrown,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$totalPoints BZPoints",
              style: GoogleFonts.darumadropOne(
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Earned points can be used to redeem exclusive benefits!",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                'assets/BZCoin.png',
                width: 40,
                height: 40,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.monetization_on,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodAnalyticsCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MoodInsightsPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: darkBrown,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(70, const Color(0xFFF86963)),
                const SizedBox(width: 5),
                _buildBar(30, const Color(0xFF67B29F)),
                const SizedBox(width: 5),
                _buildBar(40, const Color(0xFF67B29F)),
                const SizedBox(width: 5),
                _buildBar(60, greenTick),
                const SizedBox(width: 5),
                _buildBar(30, Colors.grey),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "Mood Analytics",
              style: GoogleFonts.darumadropOne(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildTodaysCard(bool hasMoodEntry, String todayMoodImage) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SchedulePage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFC7B1A6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's",
              style: GoogleFonts.darumadropOne(
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Image.asset(
              todayMoodImage,
              width: 80,
              height: 80,
              errorBuilder: (c, e, s) => const Icon(
                Icons.sentiment_satisfied_alt,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tap to check how you are doing today.",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(List<Map<String, dynamic>> reminders) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFCBB7A9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reminder",
            style: GoogleFonts.darumadropOne(fontSize: 22, color: Colors.white),
          ),
          const SizedBox(height: 10),
          if (reminders.isEmpty)
            const Text(
              "No reminders today!",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            )
          else
            ...reminders.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildReminderRow(
                  r["label"] ?? "Unknown Task",
                  r["done"] ?? false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderRow(String text, bool isDone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          isDone ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: Colors.white,
          size: 18,
        ),
      ],
    );
  }

  Widget _buildCommunityCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CommunityPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Check out\nToday's\nCommunity",
              style: GoogleFonts.darumadropOne(
                fontSize: 20,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.groups, size: 40, color: darkBrown),
            ),
          ],
        ),
      ),
    );
  }
}
