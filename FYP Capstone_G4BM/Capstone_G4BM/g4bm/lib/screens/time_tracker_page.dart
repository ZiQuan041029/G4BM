import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:g4bm/main.dart';
import 'package:intl/intl.dart';

import 'routine_scheduler_page.dart';
// --- NEW API IMPORTS ---
import '../services/api_service.dart';
import '../models/sleep_entry.dart';

class TimeTrackerPage extends StatefulWidget {
  final DateTime initialDate;
  const TimeTrackerPage({super.key, required this.initialDate});
  @override
  State<TimeTrackerPage> createState() => _TimeTrackerPageState();
}

class _TimeTrackerPageState extends State<TimeTrackerPage> {
  final List<String> _timeOptions = [];
  int _wakeUpIndex = 32; // Default ~ 8:00 AM
  int _bedTimeIndex = 88; // Default ~ 10:00 PM (Changed to 88 for 22:00)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateTimeOptions();
  }

  void _generateTimeOptions() {
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 15) {
        _timeOptions.add(
          "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF5D4037);
    final creamBg = const Color(0xFFFFF9F0);

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          brownColor.withOpacity(0.5),
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => _goToNextPage(),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Let's start your day...",
                  style: GoogleFonts.darumadropOne(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildTimePickerCard(
                  title: "When did you wake up ?",
                  icon: Icons.alarm,
                  initialIndex: _wakeUpIndex,
                  onSelectedItemChanged: (index) =>
                      setState(() => _wakeUpIndex = index),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: _buildTimePickerCard(
                  title: "What time did you go to bed ?",
                  icon: Icons.nightlight_round,
                  initialIndex: _bedTimeIndex,
                  onSelectedItemChanged: (index) =>
                      setState(() => _bedTimeIndex = index),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brownColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER FUNCTIONS ---

  Future<void> _saveAndProceed() async {
    setState(() => _isSaving = true);
    var appState = Provider.of<MyAppState>(context, listen: false);
    String realUserId = appState.currentUserId ?? "unknown_user";
    final now = DateTime.now();
    final targetDate = widget.initialDate;
    String exactDateStr = DateFormat('yyyy-MM-dd').format(widget.initialDate);

    // Extract exact hours and minutes
    List<String> wakeParts = _timeOptions[_wakeUpIndex].split(':');
    int wakeH = int.parse(wakeParts[0]);
    int wakeM = int.parse(wakeParts[1]);

    List<String> sleepParts = _timeOptions[_bedTimeIndex].split(':');
    int sleepH = int.parse(sleepParts[0]);
    int sleepM = int.parse(sleepParts[1]);

    // Build the accurate DateTimes
    DateTime wakeDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      wakeH,
      wakeM,
    );
    DateTime sleepDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      sleepH >= 18 ? targetDate.day - 1 : targetDate.day,
      sleepH,
      sleepM,
    );

    // 1. Save Wake to Timeline (Using the REAL calculated time!)
    appState.addOrUpdateEntry({
      'id': 'wake_${now.millisecondsSinceEpoch}',
      'fullDateTime': wakeDateTime,
      'time': _timeOptions[_wakeUpIndex],
      'date': exactDateStr,
      'type': 'wake',
      'label': 'Wake Up',
      'icon': Icons.alarm,
      'done': false,
      'durationMinutes': 0,
      'reminder': false,
    });

    // 2. Save Sleep to Timeline (Using the REAL calculated time!)
    appState.addOrUpdateEntry({
      'id': 'sleep_${now.millisecondsSinceEpoch}',
      'fullDateTime': sleepDateTime,
      'time': _timeOptions[_bedTimeIndex],
      'date': exactDateStr,
      'type': 'sleep',
      'label': 'Sleep',
      'icon': Icons.nightlight_round,
      'done': false,
      'durationMinutes': 0,
      'reminder': false,
    });

    // 3. Save to MongoDB
    int totalMinutes = wakeDateTime.difference(sleepDateTime).inMinutes;
    if (totalMinutes < 0) totalMinutes += 1440;

    SleepEntry newApiSleep = SleepEntry(
      userId: realUserId,
      logDate: DateFormat('yyyy-MM-dd').format(widget.initialDate),
      sleepTime: sleepDateTime,
      wakeUpTime: wakeDateTime,
      totalSleepMinutes: totalMinutes,
      sleepQuality: 3,
      createdAt: DateTime.now(),
    );

    bool success = await ApiService().createSleepEntry(newApiSleep);
    if (!success) {
      print("Warning: Failed to save sleep to database.");
    }

    // ---> 4. THE MAGIC TRIGGER! <---
    // They finished the check-in process, so tell the dashboard right now!
    await appState.markTaskComplete('hasLoggedMoodAndSleep');

    if (mounted) {
      setState(() => _isSaving = false);
      _goToNextPage();
    }
  }

  void _goToNextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RoutineSchedulerPage(initialDate: widget.initialDate),
      ),
    );
  }

  Widget _buildTimePickerCard({
    required String title,
    required IconData icon,
    required int initialIndex,
    required Function(int) onSelectedItemChanged,
  }) {
    final cardColor = const Color(0xFFBCAAA4);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 30),
                  Icon(icon, color: Colors.brown[800], size: 28),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 40,
              perspective: 0.005,
              diameterRatio: 1.05,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: initialIndex,
              ),
              onSelectedItemChanged: onSelectedItemChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: _timeOptions.length,
                builder: (context, index) => Center(
                  child: Text(
                    _timeOptions[index],
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.brown[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
