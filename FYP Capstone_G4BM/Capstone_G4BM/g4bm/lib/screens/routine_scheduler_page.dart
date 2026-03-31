import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:g4bm/main.dart';
import 'main_screen.dart';

class RoutineSchedulerPage extends StatefulWidget {
  final DateTime initialDate;
  const RoutineSchedulerPage({super.key, required this.initialDate});
  @override
  State<RoutineSchedulerPage> createState() => _RoutineSchedulerPageState();
}

class _RoutineSchedulerPageState extends State<RoutineSchedulerPage> {
  // --- STATE VARIABLES ---
  final TextEditingController _taskController = TextEditingController();
  IconData _selectedIcon = Icons.alarm; // Default icon
  late DateTime _selectedDate;
  String _duration = "30min"; // Default duration
  bool _isReminderOn = true;

  // Standard duration options for the chips
  final List<String> _standardDurations = ["30min", "45min", "1h", "5h"];

  // List of icons available in the picker
  final List<IconData> _availableIcons = [
    Icons.fitness_center,
    Icons.access_time,
    Icons.coffee,
    Icons.email,
    Icons.local_shipping,
    Icons.shopping_cart,
    Icons.local_laundry_service,
    Icons.medical_services,
    Icons.people,
    Icons.school,
    Icons.music_note,
    Icons.work,
    Icons.home,
    Icons.pets,
    Icons.directions_car,
    Icons.restaurant,
    Icons.bed,
    Icons.laptop,
    Icons.cleaning_services,
    Icons.spa,
    Icons.book,
    Icons.videogame_asset,
    Icons.palette,
  ];

  // List of suggestions to randomize
  final List<Map<String, dynamic>> _allActivities = [
    {'name': 'Go to Gym', 'icon': Icons.fitness_center},
    {'name': 'Pick up the kids', 'icon': Icons.access_time},
    {'name': 'Coffee Break', 'icon': Icons.coffee},
    {'name': 'Reply E-mails', 'icon': Icons.email},
    {'name': 'Take parcels', 'icon': Icons.local_shipping},
    {'name': 'Groceries Shopping', 'icon': Icons.shopping_cart},
    {'name': 'Laundry', 'icon': Icons.local_laundry_service},
    {'name': 'Body Check-ups', 'icon': Icons.medical_services},
    {'name': 'Meeting', 'icon': Icons.people},
    {'name': 'Parents Meeting', 'icon': Icons.school},
    {'name': 'Kid\'s Piano class', 'icon': Icons.music_note},
  ];

  late List<Map<String, dynamic>> _randomSuggestions;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _randomSuggestions = _getRandomSuggestions();
  }

  // Pick 4 random items
  List<Map<String, dynamic>> _getRandomSuggestions() {
    var list = List<Map<String, dynamic>>.from(_allActivities);
    list.shuffle();
    return list.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF5D4037);
    final cardColor = const Color(0xFFBCAAA4); // The main card background
    final creamBg = const Color(0xFFFFF9F0);

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Back, Progress, Skip)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 10,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.9, // 90% progress
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          brownColor.withOpacity(0.5),
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    // Skip sends success: false (No popup)
                    onPressed: () => _navigateToHome(success: false),
                    child: Text(
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
            ),

            // 2. TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "What's up next...",
                  style: GoogleFonts.darumadropOne(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 10),

            // 3. MAIN CARD (Scrollable Content)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE: What are we doing today?
                      Text(
                        "What are we doing today?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),

                      // INPUT FIELD
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: brownColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Icon Selector Button
                            IconButton(
                              icon: Icon(_selectedIcon, color: Colors.white),
                              onPressed: _showIconPicker,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _taskController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Create a task",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // SUGGESTIONS
                      Text(
                        "Here are some suggestions:",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _randomSuggestions.map((item) {
                          return _buildSuggestionChip(
                            item['name'],
                            item['icon'],
                            brownColor,
                          );
                        }).toList(),
                      ),

                      SizedBox(height: 25),

                      // WHEN? SECTION (Combined Date + Time Picker)
                      Text(
                        "When ?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _pickDateTime(context),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "${_formatDate(_selectedDate)}, ${_formatTime(_selectedDate)}",
                                style: TextStyle(color: Colors.white),
                              ),
                              Spacer(),
                              Text(
                                "Change >",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // DURATION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Duration",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          GestureDetector(
                            onTap:
                                _showCustomDurationPicker, // Opens scroll selector
                            child: Icon(
                              Icons.more_horiz,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _standardDurations.map((text) {
                            return _buildDurationChip(text);
                          }).toList(),
                        ),
                      ),

                      // Show Custom Duration Text below the bar if applicable
                      if (!_standardDurations.contains(_duration)) ...[
                        SizedBox(height: 10),
                        Center(
                          child: Text(
                            "Custom Duration: $_duration",
                            style: TextStyle(
                              color: brownColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 25),

                      // REMINDER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Put in reminder ?",
                            style: TextStyle(
                              color: brownColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isReminderOn = !_isReminderOn),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isReminderOn
                                    ? brownColor
                                    : Colors.transparent,
                                border: Border.all(color: brownColor, width: 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: _isReminderOn
                                    ? Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : SizedBox(width: 16, height: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20), // Bottom padding inside card
                    ],
                  ),
                ),
              ),
            ),

            // 4. SAVE BUTTON (Floating outside card)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brownColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSuggestionChip(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Auto-fill the task name and icon
        setState(() {
          _taskController.text = label;
          _selectedIcon = icon;
        });
      },
      child: Container(
        width: 140, // Fixed width for grid look
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(String text) {
    bool isSelected = _duration == text;
    return GestureDetector(
      onTap: () => setState(() => _duration = text),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFF8D6E63)
              : Colors.transparent, // Highlight if selected
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  void _saveRoutine() {
    // Validation
    if (_taskController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter a task name!")));
      return;
    }

    // 1. Get Database
    var appState = Provider.of<MyAppState>(context, listen: false);

    // 2. Prepare Data
    // We use _selectedDate (which includes time from your chained picker)
    final timeString =
        "${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}";

    // Parse duration string "30min" -> int 30
    int durationMins = 30; // Default
    if (_duration.contains("min")) {
      durationMins =
          int.tryParse(_duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 30;
    } else if (_duration.contains("h")) {
      durationMins =
          (double.parse(_duration.replaceAll(RegExp(r'[^0-9.]'), '')) * 60)
              .toInt();
    }

    // 3. Calculate End Time & Save Entry
    DateTime endTime = _selectedDate.add(Duration(minutes: durationMins));
    String endString =
        "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

    appState.addOrUpdateEntry({
      'id': 'task_${DateTime.now().millisecondsSinceEpoch}',
      'fullDateTime': _selectedDate,
      'time': timeString,
      'type': 'task',
      'label': _taskController.text,
      'end': endString,
      'icon': _selectedIcon,
      'done': false,
      'durationMinutes': durationMins,
      'reminder': _isReminderOn,
    });

    // 4. Navigate to Home
    _navigateToHome(success: true);
  }

  void _navigateToHome({required bool success}) {
    // pushAndRemoveUntil clears the back stack so user can't "back" into the signup flow
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(showSuccessDialog: success),
      ),
      (route) => false,
    );
  }

  // Chained Picker: Date -> Time
  Future<void> _pickDateTime(BuildContext context) async {
    // 1. Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Color(0xFF5D4037)),
          ),
          child: child!,
        );
      },
    );

    // 2. If Date is picked, Pick Time
    if (pickedDate != null) {
      if (!context.mounted) return; // Safety check

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Color(0xFF5D4037),
                onPrimary: Colors.white,
                onSurface: Color(0xFF5D4037),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Color(0xFF5D4037)),
              ),
            ),
            child: child!,
          );
        },
      );

      // 3. Combine Date + Time
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Custom Icon Picker Sheet
  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              Text(
                "Choose an Icon",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = _availableIcons[index];
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF5D4037),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _availableIcons[index],
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Custom Duration Picker
  void _showCustomDurationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Done",
                      style: TextStyle(color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  onTimerDurationChanged: (Duration newDuration) {
                    setState(() {
                      // Formatting logic
                      String h = newDuration.inHours > 0
                          ? "${newDuration.inHours}h"
                          : "";
                      String m = (newDuration.inMinutes % 60) > 0
                          ? " ${newDuration.inMinutes % 60}m"
                          : "";
                      String result = "$h$m".trim();
                      if (result.isEmpty) result = "1m";
                      _duration = result;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Date formatters
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
