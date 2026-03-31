import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'G4BM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D4037)),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
        ),
        home: SplashScreen(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  final String baseUrl = 'http://localhost:3000/api';
  // Helper getters for Community/Comments
  String get currentUserName => userProfile['name'];
  String get currentUserImage => userProfile['profileImage'];

  // Image Provider Helper (Solves the "File not found" and "Base64" errors)
  ImageProvider getProfileImage(String? imageSource) {
    // 1. Handle null or empty immediately
    if (imageSource == null || imageSource.isEmpty) {
      return const AssetImage('assets/default_user_pp.png');
    }

    // 2. THE FIX: Explicitly check for Asset paths
    // This stops it from falling through to FileImage
    if (imageSource.startsWith('assets/')) {
      return AssetImage(imageSource);
    }

    // 3. Handle Base64 strings (Account Page uploads)
    if (imageSource.length > 100) {
      try {
        return MemoryImage(base64Decode(imageSource));
      } catch (e) {
        return const AssetImage('assets/default_user_pp.png');
      }
    }

    // 4. Handle actual File paths (if any)
    return FileImage(File(imageSource));
  }

  MyAppState() {
    loadCommunityPosts(); // Pre-load the community feed instantly!
  }
  List<Map<String, dynamic>> familyMembers = [];

  Future<void> saveFamilyMember(Map<String, dynamic> member) async {
    if (currentUserId == null) return;

    // 1. Prepare payload (remove temp ID if it's a new member)
    Map<String, dynamic> payload = {...member, 'userId': currentUserId};
    if (member['id'] != null && member['id'].toString().length < 10) {
      payload.remove('id');
    }

    // 2. Await the server's version of the member (with the real _id)
    final savedMember = await ApiService().saveFamilyMember(payload);

    if (savedMember != null) {
      // 3. Instead of just calling loadFamilyData, let's force a fresh sync
      await loadFamilyData();
      await syncNotifications(); // <--- ADD THIS
      print("Family data synced and notifications updated.");
    } else {
      print("Failed to save family member to server.");
    }
  }

  Future<void> deleteFamilyMember(String memberId) async {
    if (currentUserId == null) return;

    // 1. Call ApiService to delete from MongoDB
    bool success = await ApiService().deleteFamilyMember(memberId);

    if (success) {
      // 2. Remove locally and notify UI
      familyMembers.removeWhere((m) => m['id'] == memberId);
      notifyListeners();
      print("Delete successful");
    } else {
      print("Delete failed on server");
    }
  }

  Future<void> toggleFamilyReminder(
    String memberId,
    String reminderTitle,
  ) async {
    // 1. Find the member in the local list
    int index = familyMembers.indexWhere((m) => m['id'] == memberId);
    if (index == -1) return;

    var member = familyMembers[index];
    List<dynamic> reminders = List.from(member['reminders']);

    // 2. Flip the isDone status for that specific title
    for (var r in reminders) {
      if (r['title'] == reminderTitle) {
        r['isDone'] = !(r['isDone'] ?? false);
        break;
      }
    }

    // 3. Save the updated member back to MongoDB
    member['reminders'] = reminders;
    await saveFamilyMember(member);
  }

  // ==========================================
  // NOTIFICATION SYNC LOGIC
  // ==========================================
  Future<void> syncNotifications() async {
    // 1. Clear old scheduled notifications to avoid duplicates
    await NotificationService().cancelAll();

    // 2. Schedule User Routine Reminders (1 hour before)
    for (var entry in _allEntries) {
      if (entry['reminder'] == true && entry['fullDateTime'] != null) {
        DateTime scheduledTime = entry['fullDateTime'];

        // Generate a unique integer ID from the string ID
        int notifyId = entry['id'].hashCode;

        await NotificationService().scheduleReminder(
          id: notifyId,
          title: "G4BM: ${entry['label']}",
          body: "Scheduled for ${entry['time']}. Get ready!",
          scheduledTime: scheduledTime,
          isFamilyReminder: false,
        );
      }
    }

    // 3. Schedule Family Reminders (Every 6 hours)
    for (var member in familyMembers) {
      List<dynamic> reminders = member['reminders'] ?? [];
      for (var r in reminders) {
        // Only remind if it's not done yet
        if (r['isDone'] == false && r['dueDate'] != null) {
          DateTime dueDate = DateTime.parse(r['dueDate']);
          int familyNotifyId = (member['id'] + r['title']).hashCode;

          await NotificationService().scheduleReminder(
            id: familyNotifyId,
            title: "Family Task: ${member['name']}",
            body: "Don't forget: ${r['title']}",
            scheduledTime: dueDate,
            isFamilyReminder: true,
          );
        }
      }
    }
    await NotificationService().checkPending();
  }

  // ==========================================
  // 1. GLOBAL APP MEMORY (Who is using the app?)
  // ==========================================
  String? currentUserId;
  String tempPassword = '';

  Future<bool> changeUserPassword(
    String currentPlainPassword,
    String newPlainPassword,
  ) async {
    print("Pretending to change password for now...");
    return true; // Fake success so the Settings page doesn't crash
  }

  // We keep userProfile so your UI can still show their name, email, etc.
  Map<String, dynamic> userProfile = {
    'name': 'Loading...',
    'username': '@username',
    'email': 'name@domain.com',
    'phone': 'Not provided',
    'location': 'Malaysia',
    'gender': 'Not specified',
    'dob': 'DD-MM-YYYY',
    'profileImage': '',
  };

  // ==========================================
  // 2. AUTHENTICATION LOGIC (Via Node.js Backend)
  // ==========================================

  // --- LOGIN EXISTING USER ---
  Future<bool> loginUser(String email, String pass) async {
    var fetched = await ApiService().loginUser(email, pass);
    if (fetched != null) {
      currentUserId = fetched['userId'];
      userProfile = {
        'name': fetched['name'] ?? 'Mama Bear',
        'username': fetched['username'] ?? '@username',
        'email': fetched['email'] ?? email,
        'phone': fetched['phone'] ?? 'Not provided',
        'location': fetched['location'] ?? 'Malaysia',
        'gender': fetched['gender'] ?? 'Not specified',
        'dob': fetched['dob'] ?? 'DD-MM-YYYY',
        'profileImage': fetched['profileImage'] ?? 'assets/default_user_pp.png',
      };
      await loadAllUserData();
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- REGISTER A NEW USER ---
  Future<bool> registerNewUser(String plainTextPassword) async {
    Map<String, dynamic> newUserPayload = {
      ...userProfile,
      'password': plainTextPassword,
      'consent': true,
    };

    String? newUserId = await ApiService().registerNewUser(newUserPayload);

    if (newUserId != null) {
      currentUserId = newUserId;
      _allEntries.clear();

      // 1. Initialize the Progress record in the DB first
      await ApiService().fetchTodayProgress(newUserId);

      // 2. Now load data (this will trigger the Welcome Bonus logic)
      await loadProgressData();

      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void logout() {
    // 1. Clear the user ID
    currentUserId = null;

    // 2. Reset the profile to defaults
    userProfile = {
      'name': 'Loading...',
      'username': '@username',
      'email': 'name@domain.com',
      'phone': 'Not provided',
      'location': 'Malaysia',
      'gender': 'Not specified',
      'dob': 'DD-MM-YYYY',
      'profileImage': '',
    };

    // 3. Wipe all sensitive lists and progress
    _allEntries.clear();
    familyMembers.clear();
    myPosts.clear();
    bzPoints = 0;
    pointHistoryLog.clear();
    pointBatches.clear();

    // 4. Update the UI
    notifyListeners();
  }

  // --- UPDATE SPECIFIC PROFILE FIELD ---
  // UPDATED: Sync Profile with Database
  void updateUserProfile(String key, String value) async {
    userProfile[key] = value;
    notifyListeners();

    if (currentUserId == null) {
      print("Cannot update: currentUserId is null!");
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('http://localhost:3000/api/users/update/$currentUserId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({key: value}),
      );

      // THE FIX: Check why it might be failing
      if (response.statusCode == 200) {
        print("Success: $key updated in MongoDB");
      } else {
        print("Server Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  // ==========================================
  // 3. MOOD & SCHEDULE DB LOGIC (Connecting to Node.js)
  // ==========================================

  String currentMood = 'Others';
  void setMood(String newMood) {
    currentMood = newMood;
    notifyListeners();
  }

  final List<Map<String, dynamic>> _allEntries = [];

  // ---> THE GATEKEEPER <---
  List<Map<String, dynamic>> getEntriesForDate(DateTime targetDate) {
    // 1. Format the calendar date we are looking for
    String exactTargetStr = DateFormat('yyyy-MM-dd').format(targetDate);

    // 2. Filter the global list (USING _allEntries!)
    var filteredList = _allEntries.where((entry) {
      // THE FIX: If the entry has our strict string tag, ONLY match the string!
      if (entry.containsKey('date') && entry['date'] != null) {
        return entry['date'] == exactTargetStr;
      }

      // Fallback: Just in case there are older entries from before we added the tag
      if (entry['fullDateTime'] != null) {
        DateTime dt = entry['fullDateTime'];
        return dt.year == targetDate.year &&
            dt.month == targetDate.month &&
            dt.day == targetDate.day;
      }

      return false;
    }).toList();

    // 3. Sort them by time so the schedule flows perfectly downwards!
    filteredList.sort((a, b) {
      if (a['fullDateTime'] != null && b['fullDateTime'] != null) {
        return (a['fullDateTime'] as DateTime).compareTo(
          b['fullDateTime'] as DateTime,
        );
      }
      return 0;
    });

    return filteredList;
  }

  List<Map<String, dynamic>> getUpcomingReminders() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _allEntries.where((entry) {
      bool hasReminder = entry['reminder'] == true;
      if (entry['fullDateTime'] == null) return false;

      DateTime entryDate = entry['fullDateTime'] as DateTime;
      return hasReminder &&
          entryDate.isAfter(todayStart.subtract(const Duration(seconds: 1)));
    }).toList()..sort((a, b) => a['fullDateTime'].compareTo(b['fullDateTime']));
  }

  // ---> FETCH DATA FROM MONGODB <---
  Future<void> loadUserRoutines() async {
    if (currentUserId == null) return;

    var fetchedRoutines = await ApiService().fetchUserRoutines(currentUserId!);

    // THE FIX: Only remove 'task' types from the timeline. Leave moods and sleep alone!
    _allEntries.removeWhere((entry) => entry['type'] == 'task');

    for (var r in fetchedRoutines) {
      bool isDone = false;
      if (r['status'] != null) {
        isDone = r['status'] == "Completed";
      } else if (r['done'] != null) {
        isDone = r['done'];
      }

      // 1. Grab start date and duration
      DateTime startDt = r['fullDateTime'] != null
          ? DateTime.parse(r['fullDateTime']).toLocal()
          : DateTime.now();
      int duration = r['duration'] ?? 0;

      // 2. Calculate the End String!
      String? endStr;
      if (duration > 0) {
        DateTime endDt = startDt.add(Duration(minutes: duration));
        endStr =
            "${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}";
      }

      _saveLocally({
        'id': r['taskId'] ?? r['_id'].toString(),
        'fullDateTime': r['fullDateTime'] != null
            ? DateTime.parse(r['fullDateTime'])
            : DateTime.now(),
        'time': r['time'] ?? "00:00",
        'type': r['type'] ?? "task",
        'label': r['taskName'] ?? r['label'] ?? "Unknown Task",
        'end': endStr,
        'durationMinutes': r['duration'] ?? 0,
        'reminder': r['isReminder'] ?? false,
        'done': isDone,
        'icon': r['iconCodePoint'] != null
            ? IconData(r['iconCodePoint'], fontFamily: 'MaterialIcons')
            : Icons.task, // Fallback icon
      });
    }
    notifyListeners();
  }

  // ---> 1. SEND DATA TO CLOUD (Traffic Director) <---
  Future<void> addOrUpdateEntry(Map<String, dynamic> entry) async {
    if (currentUserId == null) {
      _saveLocally(entry);
      await syncNotifications();
      return;
    }

    // --- ROUTE 1: TASKS ---
    if (entry['type'] == 'task') {
      bool isDone = entry['done'] ?? false;
      DateTime dt = entry['fullDateTime'] as DateTime;
      String dateString =
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

      Map<String, dynamic> dbPayload = {
        'userId': currentUserId,
        'taskId': entry['id'],
        'type': entry['type'],
        'taskName': entry['label'],
        'date': dateString,
        'time': entry['time'],
        'duration': entry['durationMinutes'] ?? 0,
        'isReminder': entry['reminder'] ?? false,
        'status': isDone ? "Completed" : "Pending",
        'fullDateTime': dt.toIso8601String(),
      };

      if (entry['icon'] is IconData) {
        dbPayload['iconCodePoint'] = (entry['icon'] as IconData).codePoint;
      }

      bool success = await ApiService().saveRoutine(dbPayload);
      if (success) {
        _saveLocally(entry);
        if (isDone) {
          markTaskComplete('hasCompletedSchedule');
        }
      }
    }
    // --- ROUTE 2 & 3: MOODS, SLEEP & WAKE ---
    else if (entry['type'] == 'mood' ||
        entry['type'] == 'sleep' ||
        entry['type'] == 'wake') {
      // TODO: Call ApiService().saveMood(entry) here!
      // For now, we just save it locally so the UI works
      _saveLocally(entry);
      final todaysEntries = getEntriesForDate(DateTime.now());
      bool hasMood = todaysEntries.any((e) => e['type'] == 'mood');
      bool hasSleep = todaysEntries.any(
        (e) => e['type'] == 'sleep' || e['type'] == 'wake',
      );
      if (hasMood && hasSleep) {
        markTaskComplete('hasLoggedMoodAndSleep');
      }
    }
  }

  // ==========================================
  // THE MASTER DOWNLOADER
  // ==========================================
  Future<void> loadAllUserData() async {
    if (currentUserId == null) return;

    // 1. Wipe the slate clean on app load
    _allEntries.clear();

    await Future.wait([
      loadUserRoutines(),
      loadUserMoods(),
      loadUserSleep(),
      loadProgressData(),
      loadFamilyData(),
    ]);

    // 3. Tell the UI to draw the finished, combined timeline!
    await syncNotifications();
    notifyListeners();
  }

  Future<void> loadFamilyData() async {
    if (currentUserId == null) return;
    var data = await ApiService().fetchFamilyMembers(currentUserId!);
    familyMembers = List<Map<String, dynamic>>.from(data).map((member) {
      return {...member, 'id': member['_id'].toString()};
    }).toList();

    notifyListeners();
  }

  // ---> MOOD TRANSLATOR <---
  Future<void> loadUserMoods() async {
    var fetchedMoods = await ApiService().fetchUserMoods(currentUserId!);

    for (var m in fetchedMoods) {
      DateTime dt = m['created_at'] != null
          ? DateTime.parse(m['created_at']).toLocal()
          : DateTime.now();
      String timeString =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

      String emoLabel = m['emotional_label'] ?? "Neutral";

      // THE FIX: Pull the strict calendar date from the database!
      // (Checking both camelCase and snake_case just in case your Node.js sends it differently)
      String exactDateStr =
          m['logDate'] ?? m['log_date'] ?? DateFormat('yyyy-MM-dd').format(dt);

      _saveLocally({
        'id': m['_id'] ?? DateTime.now().toString(),
        'type': 'mood',
        'fullDateTime': dt,
        'time': timeString,

        'date': exactDateStr, // <--- RE-ATTACHING THE STRICT TAG!

        'label': emoLabel,
        'icon': "assets/emotions/$emoLabel.png",
        'moodText': m['mood_text'] ?? "",
        'tags': m['tags'] != null ? List<String>.from(m['tags']) : [],
      });
    }
  }

  // ==========================================
  // 4. BZPOINTS & PROGRESS TRACKING
  // ==========================================
  int bzPoints = 0;
  bool alreadyClaimedToday = false;
  Map<String, bool> dailyProgress = {
    'hasLoggedMoodAndSleep': false,
    'hasCompletedSchedule': false,
    'hasInteractedWithCommunity': false,
  };

  // ---> NEW: SEPARATE LEDGER & HISTORY <---
  List<Map<String, dynamic>> pointBatches =
      []; // Used strictly for math & expiry calculation
  List<Map<String, dynamic>> pointHistoryLog = [];

  // Calculates how many points expire by Dec 31st of the CURRENT year
  int getPointsExpiringThisYear() {
    int currentYear = DateTime.now().year;
    DateTime endOfYear = DateTime(currentYear, 12, 31, 23, 59, 59);
    int expiringTotal = 0;

    for (var batch in pointBatches) {
      DateTime expiryDate = DateTime.parse(batch['expiresAt']);
      if (expiryDate.isBefore(endOfYear) ||
          expiryDate.isAtSameMomentAs(endOfYear)) {
        expiringTotal += (batch['amount'] as int);
      }
    }
    return expiringTotal;
  }

  // 1. Download today's progress when the app starts
  Future<void> loadProgressData() async {
    if (currentUserId == null) return;

    try {
      // 1. Fetch official history and progress at the SAME time
      final results = await Future.wait([
        ApiService().fetchPointHistory(currentUserId!),
        ApiService().fetchTodayProgress(currentUserId!),
      ]);

      final List<dynamic> history = results[0] as List<dynamic>;
      final Map<String, dynamic>? progressData =
          results[1] as Map<String, dynamic>?;

      print("DEBUG: Fetched Progress Data on Restart: $progressData");

      // 2. Sync History Log
      pointHistoryLog = List<Map<String, dynamic>>.from(history);

      // 3. Welcome Bonus Check (Only if not in DB history)
      bool hasWelcome = pointHistoryLog.any((b) => b['title'] == 'Welcome!');
      if (!hasWelcome) {
        DateTime now = DateTime.now();
        String expiry = DateTime(
          now.year,
          now.month + 6,
          now.day,
        ).toIso8601String();

        await ApiService().savePointTransaction({
          'userId': currentUserId,
          'amount': 10,
          'title': 'Welcome!',
          'expiresAt': expiry,
          'earnedAt': now.toIso8601String(),
        });
        // Immediately re-fetch to stay in sync
        return loadProgressData();
      }

      // 4. Update the UI Variables from the official Progress data
      if (progressData != null) {
        bzPoints = progressData['bzPoints'] ?? 0;
        alreadyClaimedToday = progressData['alreadyClaimedToday'] ?? false;

        if (progressData['dailyProgress'] != null) {
          dailyProgress['hasLoggedMoodAndSleep'] =
              progressData['dailyProgress']['hasLoggedMoodAndSleep'] ?? false;
          dailyProgress['hasCompletedSchedule'] =
              progressData['dailyProgress']['hasCompletedSchedule'] ?? false;
          dailyProgress['hasInteractedWithCommunity'] =
              progressData['dailyProgress']['hasInteractedWithCommunity'] ??
              false;
        }
      }

      // 5. Calculate expiry batches ONLY from positive points in history
      pointBatches = pointHistoryLog
          .where(
            (item) => (item['amount'] as int) > 0 && item['expiresAt'] != null,
          )
          .toList();

      notifyListeners();
    } catch (e) {
      print("Error loading progress: $e");
    }
  }

  // 2. Trigger this whenever the user does something good!
  Future<void> markTaskComplete(String taskType) async {
    if (currentUserId == null) return;

    // If they already did it today, don't waste an API call
    if (dailyProgress[taskType] == true) return;

    // Optimistically update the UI instantly
    dailyProgress[taskType] = true;
    notifyListeners();

    // Tell the backend to save it
    bool success = await ApiService().updateDailyTask(currentUserId!, taskType);
    if (!success) {
      // Revert if the server failed
      dailyProgress[taskType] = false;
      notifyListeners();
      print("Failed to save $taskType to database.");
    }
  }

  // ---> UPGRADED: CLAIM POINTS <---

  // ---> UPGRADED: CLAIM POINTS <---
  Future<bool> claimPoints() async {
    if (currentUserId == null || alreadyClaimedToday) return false;

    // 1. Tell the backend to do the math and save the receipt
    final result = await ApiService().claimBzPoints(currentUserId!);

    if (result != null && result['success'] == true) {
      // 2. THE FIX: Instantly tell the UI that we claimed it!
      alreadyClaimedToday = true;
      notifyListeners();

      // 3. Silently refresh the exact point totals in the background
      await loadProgressData();
      return true;
    }

    return false;
  }

  // ---> UPGRADED: SPEND POINTS (Database Sync + FIFO) <---
  Future<void> spendPoints(int pointsToSpend) async {
    if (currentUserId == null || bzPoints < pointsToSpend) return;

    // 1. Prepare the deduction data for the database
    Map<String, dynamic> redemptionData = {
      'userId': currentUserId,
      'amount': -pointsToSpend, // Negative number for the backend $inc
      'title': 'Redeemed Reward',
      'earnedAt': DateTime.now().toIso8601String(),
      // Redemptions don't need an expiresAt field
    };

    // 2. Send to Backend
    bool success = await ApiService().savePointTransaction(redemptionData);

    if (success) {
      // 3. Instead of doing local math, just trigger a refresh!
      // This ensures the pointBatches and bzPoints are EXACTLY what the server says.
      await loadProgressData();

      print("Redemption synced with database.");
    } else {
      print("Failed to sync redemption with database.");
    }

    notifyListeners();
  }

  // ==========================================
  // 5. AGGREGATED STATS (For Dashboard & Home)
  // ==========================================

  // A. Calculates the overall completion % for the rings
  // --- TIMELINE PROGRESS CALCULATOR ---
  double getTimeframeProgress(String timeframe) {
    if (currentUserId == null || pointHistoryLog.isEmpty) return 0.0;

    DateTime now = DateTime.now();

    // Helper: Finds how many points were earned on a specific day
    double getPointsForDay(DateTime date) {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      // We look for the "Daily Task Completion" receipt (which gives 5 points max per day)
      var dailyReceipts = pointHistoryLog.where(
        (log) =>
            log['title'] == "Daily Task Completion" &&
            log['earnedAt'] != null &&
            log['earnedAt'].toString().startsWith(dateStr),
      );

      return dailyReceipts.isNotEmpty
          ? 1.0
          : 0.0; // 1.0 means 100% complete for that day
    }

    if (timeframe == 'This Week') {
      // Logic: Average of the 7 days in the CURRENT week (Mon-Sun)
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      double totalProgress = 0.0;

      for (int i = 0; i < 7; i++) {
        DateTime day = startOfWeek.add(Duration(days: i));
        // We only calculate up to today so the average isn't ruined by future days
        if (day.isBefore(now) || day.isAtSameMomentAs(now)) {
          totalProgress += getPointsForDay(day);
        }
      }

      // Divide by the number of days that have actually passed this week
      int currentDayOfWeek = now.weekday;
      return totalProgress / currentDayOfWeek;
    } else if (timeframe == 'This Month') {
      // Logic: Average of all days passed in the CURRENT month
      double totalProgress = 0.0;

      for (int i = 1; i <= now.day; i++) {
        DateTime day = DateTime(now.year, now.month, i);
        totalProgress += getPointsForDay(day);
      }

      // Divide by today's date (e.g., if it's the 15th, divide by 15)
      return totalProgress / now.day;
    } else if (timeframe == 'This Year') {
      // Logic: Average of all months passed in the CURRENT year
      double totalYearProgress = 0.0;

      for (int month = 1; month <= now.month; month++) {
        double monthlyProgress = 0.0;
        int daysInThatMonth = (month == now.month)
            ? now.day
            : DateTime(now.year, month + 1, 0).day;

        for (int d = 1; d <= daysInThatMonth; d++) {
          DateTime day = DateTime(now.year, month, d);
          monthlyProgress += getPointsForDay(day);
        }

        // Add this month's average to the year total
        totalYearProgress += (monthlyProgress / daysInThatMonth);
      }

      // Divide by the number of months passed
      return totalYearProgress / now.month;
    }

    return 0.0;
  }

  // B. Aggregates and ranks the "Top Activities"
  List<Map<String, dynamic>> getCompletedTasksStats(String timeframe) {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (timeframe == 'This Week') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
    } else if (timeframe == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }

    // 1. Find all completed tasks in this timeframe
    var tasks = _allEntries.where((e) {
      if (e['type'] != 'task' || e['done'] != true || e['fullDateTime'] == null)
        return false;
      DateTime dt = e['fullDateTime'];
      return dt.isAfter(startDate.subtract(const Duration(days: 1))) &&
          dt.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    // 2. Add up the minutes for each type of task!
    Map<String, Map<String, dynamic>> aggregated = {};
    for (var t in tasks) {
      String label = t['label'] ?? 'Unknown';
      int duration = t['durationMinutes'] ?? 0;
      if (duration == 0) continue;

      if (!aggregated.containsKey(label)) {
        aggregated[label] = {
          'title': label,
          'totalMinutes': 0,
          'icon': t['icon'] is IconData ? t['icon'] : Icons.check_circle,
        };
      }
      aggregated[label]!['totalMinutes'] += duration;
    }

    // 3. Sort them from longest to shortest
    List<Map<String, dynamic>> sortedList = aggregated.values.toList();
    sortedList.sort((a, b) => b['totalMinutes'].compareTo(a['totalMinutes']));

    if (sortedList.isEmpty) return [];

    int maxMinutes = sortedList.first['totalMinutes'];
    List<Color> colors = [
      const Color(0xFFB6CD7C),
      const Color(0xFFFF8A65),
      const Color(0xFFFF5252),
    ];

    // 4. Format them exactly how your UI wants them!
    return sortedList.asMap().entries.map((entry) {
      int index = entry.key;
      var data = entry.value;
      int totalMins = data['totalMinutes'];

      int hours = totalMins ~/ 60;
      int mins = totalMins % 60;
      String timeStr = hours > 0 ? "${hours}hr ${mins}min" : "${mins}min";

      return {
        'title': data['title'],
        'time': timeStr,
        'icon': data['icon'],
        'color': colors[index % colors.length],
        'factor': totalMins / maxMinutes,
      };
    }).toList();
  }

  // C. Calculates progress for a specific EXACT day (For Weekly & Monthly rings)
  double getDayProgress(DateTime targetDate) {
    int totalItems = 0;
    int completedItems = 0;
    bool hasMood = false;
    bool hasSleep = false;

    for (var e in _allEntries) {
      if (e['fullDateTime'] != null) {
        DateTime dt = e['fullDateTime'];
        if (dt.year == targetDate.year &&
            dt.month == targetDate.month &&
            dt.day == targetDate.day) {
          if (e['type'] == 'task') {
            totalItems++;
            if (e['done'] == true) completedItems++;
          } else if (e['type'] == 'mood') {
            hasMood = true;
          } else if (e['type'] == 'sleep' || e['type'] == 'wake') {
            hasSleep = true;
          }
        }
      }
    }

    // Every single day has at least ONE basic goal: Checking in!
    totalItems++;
    // If they logged both mood and sleep, they get the point!
    if (hasMood && hasSleep) {
      completedItems++;
    }

    return totalItems == 0 ? 0.0 : (completedItems / totalItems);
  }

  // D. Calculates progress for an entire month (For Yearly rings)
  double getMonthProgress(int year, int month) {
    int totalItems = 0;
    int completedItems = 0;

    for (var e in _allEntries) {
      if (e['fullDateTime'] != null) {
        DateTime dt = e['fullDateTime'];
        if (dt.year == year && dt.month == month) {
          if (e['type'] == 'task') {
            totalItems++;
            if (e['done'] == true) completedItems++;
          } else if (e['type'] == 'mood' || e['type'] == 'sleep') {
            // Give them bonus points in the monthly view for logging moods and sleep!
            totalItems++;
            completedItems++;
          }
        }
      }
    }
    return totalItems == 0 ? 0.0 : (completedItems / totalItems);
  }

  String getTimeAgo(String? isoString) {
    if (isoString == null) return "Just now";
    try {
      DateTime postTime = DateTime.parse(isoString).toLocal();
      Duration diff = DateTime.now().difference(postTime);
      if (diff.inDays > 0) return "${diff.inDays}d ago";
      if (diff.inHours > 0) return "${diff.inHours}h ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
      return "Just now";
    } catch (e) {
      return "Recently";
    }
  }

  List<Map<String, dynamic>> communityPosts = [];
  bool isCommunityLoading = false;

  Future<void> loadCommunityPosts({String category = 'For You'}) async {
    isCommunityLoading = true; // Turn ON spinner
    notifyListeners();

    try {
      // THE FIX: Only get posts from the API
      var posts = await ApiService().fetchPosts(category);
      communityPosts = List<Map<String, dynamic>>.from(posts);
    } catch (e) {
      print("Error loading posts: $e");
      communityPosts = []; // Clear list if error
    }

    isCommunityLoading = false;
    notifyListeners();
  }

  // UPDATED: sharePost uses REAL user data
  Future<int> sharePost(
    String content,
    List<String> tags,
    bool anon,
    List<File> imgs,
  ) async {
    if (currentUserId == null) return 500;

    String name = anon ? "Anonymous" : currentUserName;
    String pic = anon ? "assets/default_user_pp.png" : currentUserImage;

    // 2. Catch the status code integer
    int statusCode = await ApiService().createPostWithImages(
      userId: currentUserId!,
      userName: name,
      userImage: pic,
      content: content,
      categories: tags,
      images: imgs,
    );

    // 3. Only reload the feed if it was a success
    if (statusCode == 201 || statusCode == 200) {
      await loadCommunityPosts();
    }

    // 4. Hand the code back to the UI!
    return statusCode;
  }

  Future<bool> addCommentToPost(String postId, String text) async {
    if (currentUserId == null) return false;

    Map<String, dynamic> commentData = {
      'userId': currentUserId,
      'userName': currentUserName,
      'userImage': currentUserImage,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    bool success = await ApiService().addComment(postId, commentData);

    if (success) {
      // Instead of loadCommunityPosts(), find the post locally and update it
      int index = communityPosts.indexWhere((p) => p['_id'] == postId);
      if (index != -1) {
        communityPosts[index]['comments'] ??= [];
        communityPosts[index]['comments'].add(commentData);
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  List<Map<String, dynamic>> myPosts = [];
  List<Map<String, dynamic>> likedPosts = [];

  // Fetch only posts created by the logged-in user
  Future<void> loadMyPosts() async {
    if (currentUserId == null) return;
    // You'll need to create this endpoint in Node.js
    // or filter the fetchPosts result by userId
    var all = await ApiService().fetchPosts('For you');
    myPosts = List<Map<String, dynamic>>.from(
      all,
    ).where((p) => p['userId'] == currentUserId).toList();
    notifyListeners();
  }

  // Fetch only posts that the user has liked
  Future<void> loadLikedPosts() async {
    var all = await ApiService().fetchPosts('For you');
    likedPosts = List<Map<String, dynamic>>.from(all).where((p) {
      List likes = p['likes'] ?? [];
      return likes.contains(currentUserId);
    }).toList();
    notifyListeners();
  }

  // --- HANDLE LIKE/UNLIKE (Optimistic Update) ---
  Future<void> toggleLike(String postId) async {
    if (currentUserId == null) return;

    // 1. Find the post locally and update the UI instantly (No loading screens!)
    int index = communityPosts.indexWhere((p) => p['_id'] == postId);
    if (index != -1) {
      List likes = communityPosts[index]['likes'] ?? [];
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId);
      }
      communityPosts[index]['likes'] = likes;
      notifyListeners(); // UI updates immediately
    }

    // 2. Send the actual request to Node.js in the background
    bool success = await ApiService().toggleLike(postId, currentUserId!);

    // 3. If successful, quietly refresh the Liked Posts history tab
    if (success) {
      await loadLikedPosts();
    } else {
      print("Backend failed to register the like.");
      // Optional: If you wanted to be super safe, you could revert the heart icon here.
    }
  }

  // Handle Deletion
  Future<void> deletePost(String postId) async {
    bool success = await ApiService().deletePost(postId);

    if (success) {
      // Force immediate removal from all local lists
      communityPosts.removeWhere((p) => p['_id'] == postId);
      myPosts.removeWhere((p) => p['_id'] == postId);
      likedPosts.removeWhere((p) => p['_id'] == postId);

      notifyListeners(); // This is what triggers the UI to rebuild instantly
    }
  }

  // ---> SLEEP TRANSLATOR <---
  Future<void> loadUserSleep() async {
    var fetchedSleep = await ApiService().fetchUserSleep(currentUserId!);

    for (var s in fetchedSleep) {
      // THE FIX: Pull the strict calendar date from the database!
      String exactDateStr = s['logDate'] ?? s['log_date'] ?? "";

      // Event 1: Going to bed
      if (s['sleep_time'] != null) {
        DateTime sleepDt = DateTime.parse(s['sleep_time']).toLocal();
        _saveLocally({
          'id': "${s['_id']}_sleep",
          'type': 'sleep',
          'fullDateTime': sleepDt,
          'time':
              "${sleepDt.hour.toString().padLeft(2, '0')}:${sleepDt.minute.toString().padLeft(2, '0')}",

          'date': exactDateStr.isNotEmpty
              ? exactDateStr
              : DateFormat('yyyy-MM-dd').format(sleepDt), // <--- STRICT TAG

          'label': "Sleep",
          'icon': Icons.bed,
        });
      }

      // Event 2: Waking up
      if (s['wake_up_time'] != null) {
        DateTime wakeDt = DateTime.parse(s['wake_up_time']).toLocal();
        _saveLocally({
          'id': "${s['_id']}_wake",
          'type': 'wake',
          'fullDateTime': wakeDt,
          'time':
              "${wakeDt.hour.toString().padLeft(2, '0')}:${wakeDt.minute.toString().padLeft(2, '0')}",

          'date': exactDateStr.isNotEmpty
              ? exactDateStr
              : DateFormat('yyyy-MM-dd').format(wakeDt), // <--- STRICT TAG

          'label': "Wake Up",
          'icon': Icons.wb_sunny,
        });
      }
    }
  }

  // Helper function to update the UI list
  void _saveLocally(Map<String, dynamic> entry) {
    int index = _allEntries.indexWhere((e) => e['id'] == entry['id']);
    if (index != -1) {
      _allEntries[index] = entry;
    } else {
      _allEntries.add(entry);
    }
    notifyListeners();
  }

  // ---> UPDATED: DELETE DATA FROM MONGODB <---
  Future<void> deleteEntry(String id) async {
    if (currentUserId == null) {
      _allEntries.removeWhere((e) => e['id'] == id);
      notifyListeners();
      return;
    }

    bool success = await ApiService().deleteRoutine(id);
    if (success) {
      _allEntries.removeWhere((e) => e['id'] == id);
      notifyListeners();
    } else {
      print("Failed to delete task from cloud");
    }
  }

  List<Map<String, dynamic>> get moodEntries =>
      _allEntries.where((e) => e['type'] == 'mood').toList();

  List<Map<String, dynamic>> get sleepEntries => _allEntries
      .where((e) => e['type'] == 'sleep' || e['type'] == 'wake')
      .toList();

  List<Map<String, dynamic>> get routineTasks =>
      _allEntries.where((e) => e['type'] == 'task').toList();

  // 1. DYNAMIC DAILY SCORE
  double getMentalStateScoreForDate(DateTime date) {
    final dayEntries = getEntriesForDate(date);
    if (dayEntries.isEmpty) {
      print("--- Mental State Debug [${date.day}/${date.month}] ---");
      print("NO DATA");
      print("---------------------------------------");
      return 0.0;
    }

    double totalWeight = 0.0;
    double accumulatedScore = 0.0;

    // A. Mood
    var moods = dayEntries.where((e) => e['type'] == 'mood').toList();
    double moodScore = 0.0;

    if (moods.isNotEmpty) {
      String label = moods.first['label'] ?? "Neutral";

      // Inverted scoring based on your moodScores map
      switch (label) {
        case 'Happy':
          moodScore = 1.0; // Inverted from 0.1
          break;
        case 'Neutral':
          moodScore = 0.8; // Inverted from 0.2
          break;
        case 'Tired':
        case 'Annoyed':
          moodScore = 0.6; // Inverted from 0.4
          break;
        case 'Worried':
          moodScore = 0.4; // Inverted from 0.6
          break;
        case 'Stressed':
        case 'Overwhelm':
        case 'Sad':
          moodScore = 0.3; // Inverted from 0.7
          break;
        case 'Frustrated':
          moodScore = 0.25; // Inverted from 0.75
          break;
        case 'Mad': // Represents 'angry'
          moodScore = 0.2; // Inverted from 0.8
          break;
        case 'Sick':
          moodScore = 0.1; // Custom hard-floor for illness
          break;
        case 'Others':
        default:
          moodScore = 0.0; // No score value
          break;
      }

      accumulatedScore += (moodScore * 0.4);
      totalWeight += 0.4;
    }

    // B. Sleep
    double sleepHours = calculateSleepHoursForDate(date);
    double sleepScore = 0.0;

    if (sleepHours > 0) {
      if (sleepHours <= 8.0) {
        // Under or exactly 8 hours: Standard scaling (e.g., 4 hrs = 0.5)
        sleepScore = sleepHours / 8.0;
      } else if (sleepHours <= 10.0) {
        // 8 to 10 hours: Perfect healthy sleep
        sleepScore = 1.0;
      } else {
        // OVER 10 HOURS: Penalty zone
        // Subtracts 0.2 from the score for every hour over 10
        // e.g., 11 hours = 0.8 | 12 hours = 0.6 | 13 hours = 0.4
        sleepScore = 1.0 - ((sleepHours - 10.0) * 0.2);
      }

      // Clamp ensures the score never drops below 0.0 or goes above 1.0
      sleepScore = sleepScore.clamp(0.0, 1.0);

      accumulatedScore += (sleepScore * 0.3);
      totalWeight += 0.3;
    }

    // C. Tasks
    var tasks = dayEntries.where((e) => e['type'] == 'task').toList();
    double taskScore = 0.0;
    if (tasks.isNotEmpty) {
      taskScore = tasks.where((t) => t['done'] == true).length / tasks.length;
      accumulatedScore += (taskScore * 0.3);
      totalWeight += 0.3;
    }

    double totalScore = totalWeight == 0.0
        ? 0.0
        : (accumulatedScore / totalWeight);
    // --- THE DEBUG PRINTS ---
    print("--- Mental State Debug [${date.day}/${date.month}] ---");
    print(
      "Mood: ${moods.isNotEmpty ? moods.first['label'] : 'None'} -> Score: $moodScore",
    );
    print("Sleep Hours: $sleepHours -> Score: $sleepScore");
    print(
      "Tasks Done: ${tasks.where((t) => t['done'] == true).length}/${tasks.length} -> Score: $taskScore",
    );
    print("FINAL TOTAL SCORE: $totalScore");
    print("---------------------------------------");

    return totalScore;
  }

  // 2. MENTAL STATE AVERAGER
  double getAverageMentalState(DateTime start, DateTime end) {
    double totalScore = 0.0;
    int daysWithData = 0;

    for (
      DateTime d = start;
      d.isBefore(end);
      d = d.add(const Duration(days: 1))
    ) {
      double score = getMentalStateScoreForDate(d);
      if (score > 0.0) {
        // Only average days where the user actually logged something
        totalScore += score;
        daysWithData++;
      }
    }
    return daysWithData == 0 ? 0.0 : (totalScore / daysWithData);
  }

  // 3. SLEEP AVERAGER
  double getAverageSleep(DateTime start, DateTime end) {
    double totalSleep = 0.0;
    int daysWithData = 0;

    for (
      DateTime d = start;
      d.isBefore(end);
      d = d.add(const Duration(days: 1))
    ) {
      double sleep = calculateSleepHoursForDate(d);
      if (sleep > 0.0) {
        totalSleep += sleep;
        daysWithData++;
      }
    }
    return daysWithData == 0 ? 0.0 : (totalSleep / daysWithData);
  }

  // 1. Calculate Top Emotions for the Pie Chart
  Map<String, double> getEmotionPercentages() {
    if (moodEntries.isEmpty) return {};

    Map<String, int> counts = {};
    for (var entry in moodEntries) {
      String label = entry['label'] ?? "Neutral";
      counts[label] = (counts[label] ?? 0) + 1;
    }

    // This returns EVERY emotion found in your moodEntries
    return counts.map(
      (key, value) => MapEntry(key, value / moodEntries.length),
    );
  }

  // 2. Calculate Top Activities from Completed Tasks
  List<Map<String, dynamic>> getTopActivities() {
    var completedTasks = _allEntries
        .where((e) => e['type'] == 'task' && e['done'] == true)
        .toList();

    Map<String, int> counts = {};
    for (var t in completedTasks) {
      // Safety check: skip if label is null
      String title = t['label'] ?? "Activity";
      counts[title] = (counts[title] ?? 0) + 1;
    }

    var sortedKeys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return sortedKeys.take(3).map((title) {
      return {
        'title': title,
        'time': "${counts[title]} times", // Ensure this key exists!
        'color': const Color(0xFF5D4037),
        'icon': Icons.check_circle_outline,
        'factor': (counts[title]! / 10).clamp(0.0, 1.0),
      };
    }).toList();
  }

  List<Map<String, dynamic>> getFilteredEntries(String timeframe, String type) {
    DateTime now = DateTime.now();
    DateTime startDate;

    // 1. Determine the Start Date
    if (timeframe == "This Week") {
      // THE FIX: Go back exactly 7 days from now
      startDate = now.subtract(const Duration(days: 7));
    } else if (timeframe == "This Month") {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }

    // 2. Filter _allEntries by Type and Date
    return _allEntries.where((e) {
      if (e['type'] != type || e['fullDateTime'] == null) return false;
      DateTime dt = e['fullDateTime'] as DateTime;
      return dt.isAfter(startDate) &&
          dt.isBefore(now.add(const Duration(hours: 1)));
    }).toList();
  }

  // Helper to get Mood Percentages for a specific timeframe
  Map<String, double> getEmotionStatsForTimeframe(String timeframe) {
    var entries = getFilteredEntries(timeframe, 'mood');
    if (entries.isEmpty) return {};

    Map<String, int> counts = {};
    for (var e in entries) {
      String label = e['label'] ?? "Neutral";
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts.map((key, value) => MapEntry(key, value / entries.length));
  }

  double calculateSleepHoursForDate(DateTime targetDate) {
    // 1. Get all sleep/wake entries
    final entries = _allEntries
        .where((e) => e['type'] == 'sleep' || e['type'] == 'wake')
        .toList();

    // 2. Find the 'wake' entry for this specific day
    final wakeEntry = entries.firstWhere(
      (e) =>
          e['type'] == 'wake' &&
          e['fullDateTime'].year == targetDate.year &&
          e['fullDateTime'].month == targetDate.month &&
          e['fullDateTime'].day == targetDate.day,
      orElse: () => {},
    );

    if (wakeEntry.isEmpty) return 0.0;

    // 3. Find the 'sleep' entry that happened before this wake (likely the night before)
    DateTime wakeTime = wakeEntry['fullDateTime'];
    final sleepEntry = entries
        .where(
          (e) => e['type'] == 'sleep' && e['fullDateTime'].isBefore(wakeTime),
        )
        .toList();

    if (sleepEntry.isEmpty) return 0.0;

    // Sort to get the one closest to the wake time
    sleepEntry.sort((a, b) => b['fullDateTime'].compareTo(a['fullDateTime']));
    DateTime sleepTime = sleepEntry.first['fullDateTime'];

    // 4. Calculate duration in hours
    double hours = wakeTime.difference(sleepTime).inMinutes / 60.0;
    return double.parse(
      hours.toStringAsFixed(1),
    ); // Return rounded to 1 decimal
  }
}
