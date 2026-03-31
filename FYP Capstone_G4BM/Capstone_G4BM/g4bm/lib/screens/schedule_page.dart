import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:g4bm/main.dart';
import 'mood_entry_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _selectedDate = DateTime.now();
  final Color brownColor = const Color(0xFF5D4037);
  final Color creamBg = const Color(0xFFEBE5DE);

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var rawItems = appState.getEntriesForDate(_selectedDate);

    List<Map<String, dynamic>> timelineItems = [];
    bool foundSleep = false;
    bool foundWake = false;

    for (var item in rawItems) {
      if (item['type'] == 'sleep') {
        if (!foundSleep) {
          timelineItems.add(item); // Keep the first sleep entry
          foundSleep = true;
        }
      } else if (item['type'] == 'wake') {
        if (!foundWake) {
          timelineItems.add(item); // Keep the first wake entry
          foundWake = true;
        }
      } else {
        timelineItems.add(item); // Keep all other tasks/moods
      }
    }

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
        title: Text(
          "Today's",
          style: GoogleFonts.darumadropOne(color: Colors.black, fontSize: 28),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showCalendarPicker,
              child: Container(
                margin: const EdgeInsets.only(left: 45, bottom: 20, top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
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
                    const SizedBox(width: 10),
                    Text(
                      _formatFullDate(_selectedDate),
                      style: GoogleFonts.darumadropOne(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: timelineItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: timelineItems.length,
                      itemBuilder: (context, index) {
                        final item = timelineItems[index];
                        final nextItem = index < timelineItems.length - 1
                            ? timelineItems[index + 1]
                            : null;

                        double gapSize = 30.0;
                        if (nextItem != null) {
                          if (item['label'] == 'Dinner' &&
                              nextItem['label'] == 'Sleep') {
                            gapSize = 100.0;
                          }
                        }

                        return _buildTimelineItem(
                          item,
                          index == timelineItems.length - 1,
                          gapSize,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: timelineItems.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddLogDialog(),
              backgroundColor: brownColor,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/emotions/Neutral.png',
            width: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            "You have no entry yet...",
            style: GoogleFonts.darumadropOne(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 150,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MoodEntryPage(initialDate: _selectedDate),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Start",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    Map<String, dynamic> item,
    bool isLast,
    double bottomGap,
  ) {
    double contentHeight = 50.0;
    int duration = item['durationMinutes'] ?? 0;

    if (duration > 0) {
      contentHeight = duration.toDouble();
      if (contentHeight < 50) contentHeight = 50;
      if (contentHeight > 150) contentHeight = 150;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 45,
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Text(
                item['time'],
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              GestureDetector(
                onTap: () => _handleItemTap(item),
                child: Container(
                  width: 50,
                  height: contentHeight,
                  decoration: BoxDecoration(
                    color: item['type'] == 'mood'
                        ? const Color(0xFFC8AD96)
                        : brownColor,
                    borderRadius: BorderRadius.circular(25),
                    border: item['type'] == 'wake' || item['type'] == 'sleep'
                        ? null
                        : Border.all(color: creamBg, width: 2),
                  ),
                  child: Center(child: _buildIconContent(item)),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: bottomGap, color: brownColor),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['end'] != null &&
                            item['end'].toString().isNotEmpty)
                          Text(
                            "${item['time']} - ${item['end']}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          item['label'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item['type'] == 'task' || item['type'] == 'meal')
                    GestureDetector(
                      onTap: () {
                        item['done'] = !item['done'];
                        context.read<MyAppState>().addOrUpdateEntry(item);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item['done'] ? brownColor : Colors.transparent,
                          border: Border.all(color: brownColor, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: item['done']
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : const SizedBox(width: 14, height: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContent(Map<String, dynamic> item) {
    if (item['type'] == 'mood') {
      return ClipOval(
        child: Image.asset(
          item['icon'],
          width: 30,
          height: 30,
          fit: BoxFit.cover,
        ),
      );
    }
    return Icon(item['icon'], color: Colors.white, size: 24);
  }

  // ==========================================
  // UPDATED: POPUP MENU TO SHOW TEXT & TAGS
  // ==========================================
  void _handleItemTap(Map<String, dynamic> item) {
    // Determine the text to show (fallback to "-")
    String descriptionText =
        (item['moodText'] == null || item['moodText'].toString().trim().isEmpty)
        ? "-"
        : item['moodText'];

    // Determine the tags to show
    List<dynamic> tagsList = item['tags'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: brownColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Align left for text
          children: [
            // TITLE
            Center(
              child: Text(
                item['label'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // --- MOOD DESCRIPTION & TAGS DISPLAY ---
            if (item['type'] == 'mood') ...[
              const Text(
                "Description:",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                descriptionText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 15),

              const Text(
                "Tags:",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (tagsList.isEmpty)
                const Text(
                  "-",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                )
              else
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: tagsList
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            tag.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 25),
            ],
            // ----------------------------------------

            // CHANGE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  if (item['type'] == 'wake' || item['type'] == 'sleep') {
                    _showWakeSleepPicker(item);
                  } else if (item['type'] == 'mood') {
                    _openMoodEditorFlow(item);
                  } else {
                    _showAddLogDialog(existingItem: item);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                ),
                child: const Text(
                  "Change",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // DELETE BUTTON
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDelete(item);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMoodEditorFlow(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => MoodEditorDialog(
        initialMoodLabel: item['label'],
        onNext: (newLabel, newIconPath) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (!mounted) return;
            // Passes the existing text and tags into the bottom sheet!
            _showMoodDetailsSheet(item, newLabel, newIconPath);
          });
        },
      ),
    );
  }

  void _showMoodDetailsSheet(
    Map<String, dynamic> item,
    String newLabel,
    String newIconPath,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodDetailsEditorSheet(
        moodLabel: newLabel,
        initialText: item['moodText'], // <--- Pre-fills the text field
        initialTags: item['tags'] != null
            ? List<String>.from(item['tags'])
            : [], // <--- Pre-fills the tags
        onConfirm: (String text, List<String> tags) {
          item['label'] = newLabel;
          item['icon'] = newIconPath;
          item['moodText'] = text;
          item['tags'] = tags;

          context.read<MyAppState>().addOrUpdateEntry(item);
        },
      ),
    );
  }

  void _showWakeSleepPicker(Map<String, dynamic> originalItem) {
    bool isWakeUp = originalItem['type'] == 'wake';
    TimeOfDay initialTime = TimeOfDay.now();
    if (originalItem['time'] != null && originalItem['time'].contains(':')) {
      final parts = originalItem['time'].split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    DateTime tempDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      initialTime.hour,
      initialTime.minute,
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFFFF9F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWakeUp
                      ? "When did you wake up?"
                      : "What time are you going to bed?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: GoogleFonts.inter(
                          color: brownColor,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: tempDateTime,
                      use24hFormat: true,
                      onDateTimeChanged: (DateTime newTime) {
                        tempDateTime = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          newTime.hour,
                          newTime.minute,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Map<String, dynamic> newItem = Map.from(originalItem);
                      final timeString =
                          "${tempDateTime.hour.toString().padLeft(2, '0')}:${tempDateTime.minute.toString().padLeft(2, '0')}";
                      newItem['fullDateTime'] = tempDateTime;
                      newItem['time'] = timeString;
                      context.read<MyAppState>().addOrUpdateEntry(newItem);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brownColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddLogDialog({Map<String, dynamic>? existingItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLogSheet(
        existingItem: existingItem,
        initialDate: _selectedDate,
        onSave: (newItem) {
          context.read<MyAppState>().addOrUpdateEntry(newItem);
        },
        onDelete: (item) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _confirmDelete(item);
          });
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Entry?"),
        content: Text("Are you sure you want to remove '${item['label']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<MyAppState>().deleteEntry(item['id']);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCalendarPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: brownColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatFullDate(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
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
    return "${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}";
  }
}

// ==========================================
// MOOD EDITOR DIALOG (Step 1)
// ==========================================
class MoodEditorDialog extends StatefulWidget {
  final String initialMoodLabel;
  final Function(String, String) onNext;

  const MoodEditorDialog({
    super.key,
    required this.initialMoodLabel,
    required this.onNext,
  });

  @override
  State<MoodEditorDialog> createState() => _MoodEditorDialogState();
}

class _MoodEditorDialogState extends State<MoodEditorDialog> {
  late String _selectedMood;

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

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMoodLabel;
  }

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF5D4037);

    return Dialog(
      backgroundColor: const Color(0xFFFFF9F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "How did you feel?",
              style: GoogleFonts.darumadropOne(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _moods.length,
                itemBuilder: (context, index) {
                  final mood = _moods[index];
                  final isSelected = _selectedMood == mood['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood['label']!),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? brownColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(mood['image']!, height: 40),
                          const SizedBox(height: 5),
                          Text(
                            mood['label']!,
                            style: TextStyle(
                              fontSize: 10,
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

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final asset = _moods.firstWhere(
                    (m) => m['label'] == _selectedMood,
                  )['image']!;
                  widget.onNext(_selectedMood, asset);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: brownColor),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MOOD DETAILS EDITOR SHEET (Step 2)
// ==========================================
class MoodDetailsEditorSheet extends StatefulWidget {
  final String moodLabel;
  final String? initialText;
  final List<String>? initialTags;
  final Function(String, List<String>) onConfirm;

  const MoodDetailsEditorSheet({
    super.key,
    required this.moodLabel,
    this.initialText,
    this.initialTags,
    required this.onConfirm,
  });

  @override
  State<MoodDetailsEditorSheet> createState() => _MoodDetailsEditorSheetState();
}

class _MoodDetailsEditorSheetState extends State<MoodDetailsEditorSheet> {
  late TextEditingController textController;

  // ---> THE TRICK: Making this STATIC keeps your custom tags alive! <---
  static List<String> globalAvailableTags = [
    'Work',
    'Study',
    'Child',
    'Health',
    'Sleep',
  ];

  List<String> selectedTags = [];
  TextEditingController customTagController = TextEditingController();

  final Color brownColor = const Color(0xFF5D4037);
  final Color creamBg = const Color(0xFFFFF9F0);

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.initialText ?? "");

    if (widget.initialTags != null) {
      selectedTags.addAll(widget.initialTags!);
      for (String tag in selectedTags) {
        if (!globalAvailableTags.contains(tag)) {
          globalAvailableTags.add(tag);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              style: GoogleFonts.darumadropOne(fontSize: 26, color: brownColor),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Why are you feeling ${widget.moodLabel}? (Optional)",
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

            Text(
              "Tags",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ...globalAvailableTags.map((tag) {
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
                      setState(() {
                        if (selected) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),

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
                                if (customTagController.text.isNotEmpty) {
                                  setState(() {
                                    globalAvailableTags.add(
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

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onConfirm(textController.text, selectedTags);
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
  }
}

// ==========================================
// TASK EDITOR (ADD LOG SHEET)
// ==========================================
class AddLogSheet extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  final DateTime initialDate;
  final Function(Map<String, dynamic>) onSave;
  final Function(Map<String, dynamic>)? onDelete;

  const AddLogSheet({
    super.key,
    this.existingItem,
    required this.initialDate,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<AddLogSheet> {
  final TextEditingController _taskController = TextEditingController();
  IconData _selectedIcon = Icons.access_time;
  late DateTime _startDateTime;
  Duration _duration = const Duration(minutes: 30);
  bool _reminder = true;

  final Color brownColor = const Color(0xFF5D4037);
  final List<String> _standardDurations = ["30min", "45min", "1h", "2h"];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDateTime = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      now.hour,
      now.minute,
    );

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _taskController.text = item['label'];
      _selectedIcon = item['icon'] is IconData ? item['icon'] : Icons.edit;
      _duration = Duration(minutes: item['durationMinutes']);
      _reminder = item['reminder'] ?? false;

      if (item['fullDateTime'] != null) {
        _startDateTime = item['fullDateTime'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String durationLabel = _formatDuration(_duration);
    bool isEditing = widget.existingItem != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFEBE5DE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onDelete != null) {
                      widget.onDelete!(widget.existingItem!);
                    }
                  },
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              GestureDetector(
                onTap: _showIconPicker,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: brownColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_selectedIcon, color: Colors.white),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _taskController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Add a Task",
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          if (!isEditing) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF424242),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Here are some suggestions:",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  _buildSmartSuggestion(
                    Icons.tv,
                    "Watch a movie",
                    "20:00 - 22:00 (2hr)",
                    20,
                    00,
                    120,
                  ),
                  const Divider(color: Colors.white24),
                  _buildSmartSuggestion(
                    Icons.book,
                    "Read a Book",
                    "20:30 - 22:00 (1hr 30min)",
                    20,
                    30,
                    90,
                  ),
                  const Divider(color: Colors.white24),
                  _buildSmartSuggestion(
                    Icons.self_improvement,
                    "Meditate",
                    "20:30 - 21:15 (45 min)",
                    20,
                    30,
                    45,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],

          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: brownColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_formatDate(_startDateTime)}, ${_formatTime(_startDateTime)}",
                    style: TextStyle(
                      color: brownColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Change >",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          const Text(
            "Duration",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDurationChip(const Duration(minutes: 30), "30min"),
                _buildDurationChip(const Duration(minutes: 45), "45min"),
                _buildDurationChip(const Duration(hours: 1), "1h"),
                _buildDurationChip(const Duration(hours: 2), "2h"),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _pickCustomDuration,
                ),
              ],
            ),
          ),
          if (!_standardDurations.contains(durationLabel)) ...[
            const SizedBox(height: 5),
            Center(
              child: Text(
                "Custom: $durationLabel",
                style: TextStyle(
                  color: brownColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Put in reminder ?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _reminder = !_reminder),
                child: Icon(
                  _reminder ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: brownColor,
                ),
              ),
            ],
          ),
          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _handleSave() {
    if (_taskController.text.isEmpty) return;
    DateTime endTime = _startDateTime.add(_duration);

    // THE FIX: Explicitly format the exact calendar date
    String exactDateStr =
        "${_startDateTime.year}-${_startDateTime.month.toString().padLeft(2, '0')}-${_startDateTime.day.toString().padLeft(2, '0')}";

    Map<String, dynamic> item = {
      'id': widget.existingItem?['id'] ?? DateTime.now().toString(),
      'fullDateTime': _startDateTime,
      'time': _formatTime(_startDateTime),

      'date': exactDateStr, // <--- ADD THIS LINE to lock it to the calendar!

      'type': 'task',
      'label': _taskController.text,
      'end': _formatTime(endTime),
      'icon': _selectedIcon,
      'done': widget.existingItem?['done'] ?? false,
      'durationMinutes': _duration.inMinutes,
      'reminder': _reminder,
    };

    widget.onSave(item);
    Navigator.pop(context);
  }

  Widget _buildSmartSuggestion(
    IconData icon,
    String title,
    String sub,
    int hour,
    int min,
    int durMinutes,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _taskController.text = title;
          _selectedIcon = icon;
          _startDateTime = DateTime(
            _startDateTime.year,
            _startDateTime.month,
            _startDateTime.day,
            hour,
            min,
          );
          _duration = Duration(minutes: durMinutes);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: brownColor),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDateTime),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: brownColor),
          ),
          child: child!,
        ),
      );
      if (pickedTime != null) {
        setState(
          () => _startDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ),
        );
      }
    }
  }

  void _pickCustomDuration() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 200,
        child: CupertinoTimerPicker(
          mode: CupertinoTimerPickerMode.hm,
          initialTimerDuration: _duration,
          onTimerDurationChanged: (d) => setState(() => _duration = d),
        ),
      ),
    );
  }

  void _showIconPicker() {
    final List<IconData> icons = [
      Icons.fitness_center,
      Icons.book,
      Icons.work,
      Icons.restaurant,
      Icons.bed,
      Icons.local_grocery_store,
      Icons.tv,
      Icons.music_note,
    ];
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: icons.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              setState(() => _selectedIcon = icons[i]);
              Navigator.pop(context);
            },
            child: CircleAvatar(
              backgroundColor: brownColor,
              child: Icon(icons[i], color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(Duration d, String label) {
    bool isSelected = _duration == d;
    return GestureDetector(
      onTap: () => setState(() => _duration = d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brownColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes == 30) return "30min";
    if (d.inMinutes == 45) return "45min";
    if (d.inMinutes == 60) return "1h";
    if (d.inMinutes == 120) return "2h";
    return "${d.inHours}h ${d.inMinutes % 60}m";
  }

  String _formatDate(DateTime date) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = [
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
    return "${days[date.weekday == 7 ? 0 : date.weekday]}, ${months[date.month - 1]} ${date.day} ${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
