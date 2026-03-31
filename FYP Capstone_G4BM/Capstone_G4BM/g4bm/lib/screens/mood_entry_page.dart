import 'package:flutter/material.dart';
import 'package:g4bm/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'time_tracker_page.dart';
import '../services/api_service.dart';
import '../models/mood_entry.dart';

class MoodEntryPage extends StatefulWidget {
  final DateTime initialDate;
  final String userName;

  const MoodEntryPage({
    super.key,
    this.userName = "User",
    required this.initialDate,
  });

  @override
  State<MoodEntryPage> createState() => _MoodEntryPageState();
}

class _MoodEntryPageState extends State<MoodEntryPage> {
  String? _selectedMood;
  bool _isSaving = false;

  final List<Map<String, String>> _moods = [
    {'label': 'Neutral', 'image': 'assets/emotions/Neutral.png'},
    {'label': 'Happy', 'image': 'assets/emotions/Happy.png'},
    {'label': 'Sad', 'image': 'assets/emotions/Sad.png'},
    {'label': 'Annoyed', 'image': 'assets/emotions/Annoyed.png'},
    {'label': 'Mad', 'image': 'assets/emotions/Mad.png'},
    {'label': 'Worried', 'image': 'assets/emotions/Worried.png'},
    {'label': 'Overwhelm', 'image': 'assets/emotions/Overwhelm.png'},
    {'label': 'Tired', 'image': 'assets/emotions/Tired.png'},
    {'label': 'Sick', 'image': 'assets/emotions/Sick.png'},
    {'label': 'Stressed', 'image': 'assets/emotions/Stressed.png'},
    {'label': 'Frustrated', 'image': 'assets/emotions/Frustrated.png'},
    {'label': 'Others', 'image': 'assets/emotions/Others.png'},
  ];

  final Color brownColor = const Color(0xFF5D4037);
  final Color creamBg = const Color(0xFFFFF9F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            children: [
              // HEADER
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 0.3,
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
                    onPressed: () => _goToNextPage(skip: true),
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

              // DATE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: brownColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getFormattedDate(),
                      style: GoogleFonts.darumadropOne(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TITLES
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Dear Mamas..or papas,",
                  style: GoogleFonts.darumadropOne(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "How are you feeling today?",
                  style: GoogleFonts.darumadropOne(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // MOOD GRID
              Expanded(
                child: GridView.builder(
                  itemCount: _moods.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final mood = _moods[index];
                    final isSelected = _selectedMood == mood['label'];

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedMood = mood['label']),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? brownColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(mood['image']!, height: 60),
                            const SizedBox(height: 8),
                            Text(
                              mood['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // SAVE BUTTON (Now opens the Bottom Sheet!)
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedMood == null || _isSaving
                      ? null
                      : () => _showDetailsBottomSheet(), // <--- CHANGED THIS
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brownColor,
                    disabledBackgroundColor: Colors.grey[300],
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

  // ==========================================
  // NEW: THE DETAILS BOTTOM SHEET UI
  // ==========================================
  void _showDetailsBottomSheet() {
    TextEditingController textController = TextEditingController();
    List<String> availableTags = ['Work', 'Study', 'Child', 'Health', 'Sleep'];
    List<String> selectedTags = [];
    TextEditingController customTagController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(
                  context,
                ).viewInsets.bottom, // Moves up with keyboard
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tell us more...",
                      style: GoogleFonts.darumadropOne(
                        fontSize: 26,
                        color: brownColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 1. DESCRIPTION TEXT FIELD
                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            "Why are you feeling $_selectedMood? (Optional)",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: creamBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. TAGS SECTION
                    Text(
                      "Tags",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ...availableTags.map((tag) {
                          bool isSelected = selectedTags.contains(tag);
                          return ChoiceChip(
                            label: Text(tag),
                            selected: isSelected,
                            selectedColor: brownColor,
                            backgroundColor: creamBg,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : brownColor,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: brownColor, width: 1),
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),

                        // 3. THE "+ ADD" BUTTON
                        ActionChip(
                          label: const Text('+ Add'),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          onPressed: () {
                            // Show tiny dialog to type a new tag
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Add Custom Tag"),
                                  content: TextField(
                                    controller: customTagController,
                                    decoration: const InputDecoration(
                                      hintText: "e.g. Traffic",
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (customTagController
                                            .text
                                            .isNotEmpty) {
                                          setModalState(() {
                                            availableTags.add(
                                              customTagController.text.trim(),
                                            );
                                            selectedTags.add(
                                              customTagController.text.trim(),
                                            );
                                          });
                                          customTagController.clear();
                                        }
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Add"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 4. CONFIRM BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                          _goToNextPage(
                            skip: false,
                            moodText: textController.text,
                            tags: selectedTags,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brownColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
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
            );
          },
        );
      },
    );
  }

  // --- HELPER FUNCTIONS ---

  // NOTE: Added optional moodText and tags parameters!
  Future<void> _goToNextPage({
    required bool skip,
    String? moodText,
    List<String>? tags,
  }) async {
    if (!skip && _selectedMood != null) {
      setState(() => _isSaving = true);

      var appState = Provider.of<MyAppState>(context, listen: false);
      String realUserId = appState.currentUserId ?? "unknown_user";
      appState.setMood(_selectedMood!);

      final now = DateTime.now();
      final timeString =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      String exactDateStr = DateFormat('yyyy-MM-dd').format(widget.initialDate);

      appState.addOrUpdateEntry({
        'id': 'mood_${now.millisecondsSinceEpoch}',
        'fullDateTime': widget.initialDate,
        'time': timeString,
        'date': exactDateStr,
        'type': 'mood',
        'label': _selectedMood,
        'icon': 'assets/emotions/$_selectedMood.png',
        'moodText': moodText ?? "",
        'tags': tags ?? [],
        'done': false,
        'durationMinutes': 0,
        'reminder': false,
      });

      int moodValue = 3;
      if (['Happy'].contains(_selectedMood))
        moodValue = 5;
      else if (['Neutral'].contains(_selectedMood))
        moodValue = 4;
      else if (['Sad', 'Tired', 'Worried'].contains(_selectedMood))
        moodValue = 2;
      else if ([
        'Mad',
        'Stressed',
        'Frustrated',
        'Overwhelm',
        'Sick',
      ].contains(_selectedMood))
        moodValue = 1;

      MoodEntry newApiMood = MoodEntry(
        userId: realUserId,
        logDate: DateFormat('yyyy-MM-dd').format(widget.initialDate),
        moodValue: moodValue,
        moodText: moodText, // <--- NOW PASSING THE USER'S TEXT
        tags: tags, // <--- NOW PASSING THE USER'S TAGS
        sentimentScore: 0.5,
        emotionalLabel: _selectedMood!,
        createdAt: DateTime.now(),
      );

      bool success = await ApiService().createMoodEntry(newApiMood);
      if (!success) {
        print("Warning: Failed to save mood to database.");
      }

      if (mounted) setState(() => _isSaving = false);
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TimeTrackerPage(initialDate: widget.initialDate),
        ),
      );
    }
  }

  String _getFormattedDate() {
    final targetDate = widget.initialDate;
    final weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${weekDays[targetDate.weekday - 1]}, ${targetDate.day} ${months[targetDate.month - 1]} ${targetDate.year}";
  }
}
