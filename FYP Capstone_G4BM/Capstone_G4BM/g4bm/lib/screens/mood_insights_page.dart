import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import to access MyAppState
import 'package:fl_chart/fl_chart.dart';

class MoodInsightsPage extends StatefulWidget {
  const MoodInsightsPage({super.key});

  @override
  State<MoodInsightsPage> createState() => _MoodInsightsPageState();
}

class _MoodInsightsPageState extends State<MoodInsightsPage> {
  String _selectedTimeframe = "This Week";

  final List<String> _timeframes = ["This Week", "This Month", "This Year"];

  final Map<String, Color> emotionColors = {
    'Happy': const Color(0xFFBDE076), // Light Green
    'Neutral': const Color(0xFFD9E076), // Yellow-Green
    'Sad': const Color(0xFF8AB3FF), // Soft Blue
    'Annoyed': const Color(0xFFFFB38A), // Orange
    'Mad': const Color(0xFFFF8A8A), // Red
    'Worried': const Color(0xFFBA68C8), // Purple
    'Overwhelm': const Color(0xFF9575CD), // Deep Purple
    'Tired': const Color(0xFFB0BEC5), // Grey-Blue
    'Sick': const Color(0xFF81C784), // Muted Green
    'Stressed': const Color(0xFFFFD54F), // Amber
    'Frustrated': const Color(0xFF4FC3F7), // Light Blue
    'Others': Colors.grey, // Default
  };

  @override
  Widget build(BuildContext context) {
    final creamBg = const Color(0xFFEBE5DE);
    var appState = context.watch<MyAppState>();
    final emotionStats = appState.getEmotionStatsForTimeframe(
      _selectedTimeframe,
    );
    final topActivities = appState.getCompletedTasksStats(_selectedTimeframe);

    // 2. Check if everything is completely empty
    final myMoods = appState.getFilteredEntries(_selectedTimeframe, 'mood');
    final mySleep = appState.getFilteredEntries(_selectedTimeframe, 'sleep');
    final myTasks = appState.getFilteredEntries(_selectedTimeframe, 'task');
    bool hasNoData = myMoods.isEmpty && mySleep.isEmpty && myTasks.isEmpty;

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
          "Mood Insights",
          style: GoogleFonts.darumadropOne(color: Colors.black, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // 1. TIMELINE SELECTOR
            _buildTimeframeSelector(),

            const SizedBox(height: 20),

            if (hasNoData)
              _buildNoDataPlaceholder()
            else ...[
              _buildMentalStateCard(appState, _selectedTimeframe),
              const SizedBox(height: 20),
              _buildSummaryCard(),
              const SizedBox(height: 20),
              _buildSleepQualityCard(context, appState, _selectedTimeframe),
              const SizedBox(height: 20),
              _buildTopEmotionCard(appState, emotionStats, _selectedTimeframe),
              const SizedBox(height: 20),
              _buildSharedTopActivityCard("Top Activities", topActivities),
              const SizedBox(height: 20),
              _buildSuggestedActivitiesCard(),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: TIMELINE SELECTOR ---
  Widget _buildTimeframeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _timeframes.map((time) {
        bool isSelected = _selectedTimeframe == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTimeframe = time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF5D4037) : Colors.grey[400],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMentalStateCard(MyAppState appState, String timeframe) {
    int barCount = timeframe == "This Week"
        ? 7
        : (timeframe == "This Month" ? 4 : 12);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF634B3E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeframe, // Shows "This Week", etc.
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Overall Mental State",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildLegendBox(),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(barCount, (index) {
            String label;
            double progress = 0.0;
            DateTime now = DateTime.now();

            if (timeframe == "This Week") {
              DateTime date = now.subtract(Duration(days: 6 - index));
              label = date.day.toString();
              progress = appState.getMentalStateScoreForDate(date);
            } else if (timeframe == "This Month") {
              label = "W${index + 1}";
              // Calendar weeks: 1-7, 8-14, 15-21, 22-End of month
              DateTime start = DateTime(now.year, now.month, (index * 7) + 1);
              DateTime end = (index == 3)
                  ? DateTime(now.year, now.month + 1, 1)
                  : start.add(const Duration(days: 7));
              progress = appState.getAverageMentalState(start, end);
            } else {
              List<String> months = [
                "J",
                "F",
                "M",
                "A",
                "M",
                "J",
                "J",
                "A",
                "S",
                "O",
                "N",
                "D",
              ];
              label = months[index];
              DateTime start = DateTime(now.year, index + 1, 1);
              DateTime end = (index == 11)
                  ? DateTime(now.year + 1, 1, 1)
                  : DateTime(now.year, index + 2, 1);
              progress = appState.getAverageMentalState(start, end);
            }

            // Map progress to colors
            Color barColor = Colors.grey[600]!; // No Data Color
            if (progress == 0.0) {
              barColor = Colors.grey[600]!;
            } else if (progress >= 0.8) {
              barColor = const Color(0xFFBDE076);
            } else if (progress >= 0.5) {
              barColor = const Color(0xFFD9E076);
            } else if (progress >= 0.3) {
              barColor = const Color(0xFFFFB38A);
            } else {
              barColor = const Color(0xFFFF8A8A);
            }

            return _buildRealBar(label, progress, barColor);
          }),
        ],
      ),
    );
  }

  Widget _buildRealBar(String label, double factor, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor.clamp(
                0.05,
                1.0,
              ), // Ensure bar is always visible
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Activeness",
            style: TextStyle(color: Colors.white, fontSize: 8),
          ),
          _LegendItem(color: Color(0xFFBDE076), label: "Excellent"),
          _LegendItem(color: Color(0xFFD9E076), label: "Positive"),
          _LegendItem(color: Color(0xFFFFB38A), label: "Moderate"),
          _LegendItem(color: Color(0xFFFF8A8A), label: "Low"),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: SUMMARY CARD ---
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFBCAAA4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Summary",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text("• Mood Stability: 65% (▲ 10% from last week)"),
          const Text("• Active Days: 18/30 (▼ 3 days)"),
          const Text("• Sleep Quality: 72% (▲ 15%)"),
          const SizedBox(height: 15),
          Center(
            child: Text(
              "\"You had a week of low activity, but your sleep schedule improved significantly!\"",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TOP EMOTION REAL DATA ---
  Widget _buildTopEmotionCard(
    MyAppState appState,
    Map<String, double> stats,
    String timeframe,
  ) {
    // 1. Fallback for center image
    String topEmo = stats.entries.isEmpty
        ? "Neutral"
        : stats.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your top emotion ${_selectedTimeframe.toLowerCase()}.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // --- THE CHART AREA ---
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // THE FIX: If stats is empty, show a grey ring so it doesn't look broken
                    if (stats.isEmpty)
                      const CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 20,
                        color: Color(0xFFEEEEEE),
                      )
                    else
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                          // THE FIX: Ensure sections list is never empty
                          sections: stats.entries.map((entry) {
                            return PieChartSectionData(
                              color: emotionColors[entry.key] ?? Colors.grey,
                              value: (entry.value * 100).toDouble(),
                              radius: 20,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),

                    // The Bear (Always visible)
                    Image.asset(
                      'assets/emotions/$topEmo.png',
                      width: 65,
                      height: 65,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.face, size: 50),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // --- THE STATS LIST ---
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: stats.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _EmotionStat(
                        color: emotionColors[e.key] ?? Colors.grey,
                        label: e.key,
                        value: "${(e.value * 100).toInt()}%",
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityCard(
    BuildContext context,
    MyAppState appState,
    String timeframe,
  ) {
    int barCount = timeframe == "This Week"
        ? 7
        : (timeframe == "This Month" ? 4 : 12);
    // Skinnier bars for Yearly view to prevent pixel overflow
    double barWidth = timeframe == "This Year" ? 16.0 : 30.0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          Text(
            "Sleep Quality",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(barCount, (index) {
                String label;
                double hours = 0.0;
                DateTime now = DateTime.now();

                if (timeframe == "This Week") {
                  // Last 7 days rolling
                  DateTime date = now.subtract(Duration(days: 6 - index));
                  label = ["M", "T", "W", "T", "F", "S", "S"][date.weekday - 1];
                  hours = appState.calculateSleepHoursForDate(date);
                } else if (timeframe == "This Month") {
                  // 4 Weeks of the current month
                  label = "W${index + 1}";
                  DateTime start = DateTime(
                    now.year,
                    now.month,
                    (index * 7) + 1,
                  );
                  DateTime end = (index == 3)
                      ? DateTime(now.year, now.month + 1, 1)
                      : start.add(const Duration(days: 7));
                  hours = appState.getAverageSleep(start, end);
                } else {
                  // 12 Months of the current year
                  List<String> months = [
                    "J",
                    "F",
                    "M",
                    "A",
                    "M",
                    "J",
                    "J",
                    "A",
                    "S",
                    "O",
                    "N",
                    "D",
                  ];
                  label = months[index];
                  DateTime start = DateTime(now.year, index + 1, 1);
                  DateTime end = (index == 11)
                      ? DateTime(now.year + 1, 1, 1)
                      : DateTime(now.year, index + 2, 1);
                  hours = appState.getAverageSleep(start, end);
                }

                return _buildVerticalBar(label, hours, barWidth);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBar(String day, double hours, double width) {
    double maxHeight = 100.0;
    // We divide by 12.0 here so a 12-hour sleep fills the whole bar visually.
    double heightFactor = (hours / 12.0).clamp(0.0, 1.0);

    // --- SLEEP PILLAR COLOR LOGIC ---
    Color barColor;
    if (hours == 0) {
      barColor = Colors.grey[300]!; // No data
    } else if (hours < 6.0) {
      barColor = const Color(0xFFFF8A8A); // RED: Under 6 hours
    } else if (hours < 7.0) {
      barColor = const Color(0xFFFFB38A); // ORANGE: 6-7 hours
    } else {
      barColor = const Color(0xFF1A237E); // DARK BLUE: Healthy
    }

    // Format the hours text cleanly (e.g., 7.5h or 8.0h)
    String hoursText = hours > 0 ? "${hours.toStringAsFixed(1)}h" : "-";

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          hoursText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: barColor,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background Track
            Container(
              width: width,
              height: maxHeight,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Actual Data Bar
            Container(
              width: width,
              height: maxHeight * heightFactor,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // --- SHARED TOP ACTIVITY ---
  Widget _buildSharedTopActivityCard(
    String title,
    List<Map<String, dynamic>> activities,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                activity['title']?.toString() ?? "Activity",
                activity['time']?.toString() ?? "0m",
                (activity['icon'] is IconData) ? activity['icon'] : Icons.stars,
                (activity['color'] is Color)
                    ? activity['color']
                    : const Color(0xFFB6CD7C),
                (activity['factor'] is num)
                    ? (activity['factor'] as num).toDouble()
                    : 0.0,
              ),
            );
          }),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB6CD7C),
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

  // Helper for the Activity Rows (Visual Consistency)
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

  Widget _buildNoDataPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.only(top: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "No data yet",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Log your moods, sleep, or complete tasks to see your insights for ${_selectedTimeframe.toLowerCase()}.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: SUGGESTED ACTIVITIES ---
  Widget _buildSuggestedActivitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Suggested Activities",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.tv, color: Colors.white),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tomorrow, Mon 01 Jun 2025",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "Watch a movie",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Sub-widgets for cleaner code
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)),
      ],
    );
  }
}

class _EmotionStat extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _EmotionStat({
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
