class SleepEntry {
  final String? id;
  final String userId;
  final String logDate; // The date of the morning they woke up
  final DateTime sleepTime;
  final DateTime wakeUpTime;
  final int totalSleepMinutes; // Calculated locally before saving
  final int sleepQuality; // 1 to 5 scale
  final DateTime createdAt;

  SleepEntry({
    this.id,
    required this.userId,
    required this.logDate,
    required this.sleepTime,
    required this.wakeUpTime,
    required this.totalSleepMinutes,
    required this.sleepQuality,
    required this.createdAt,
  });

  // 1. Convert JSON from MongoDB into a Dart Object
  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    return SleepEntry(
      id: json['_id']?.toString(),
      userId: json['user_id'] ?? '',
      logDate: json['log_date'] ?? '',
      sleepTime: json['sleep_time'] != null
          ? DateTime.parse(json['sleep_time'])
          : DateTime.now(),
      wakeUpTime: json['wake_up_time'] != null
          ? DateTime.parse(json['wake_up_time'])
          : DateTime.now(),
      totalSleepMinutes: json['total_sleep_minutes'] ?? 0,
      sleepQuality: json['sleep_quality'] ?? 3,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // 2. Convert Dart Object back into JSON to send to MongoDB
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'user_id': userId,
      'log_date': logDate,
      'sleep_time': sleepTime.toIso8601String(),
      'wake_up_time': wakeUpTime.toIso8601String(),
      'total_sleep_minutes': totalSleepMinutes,
      'sleep_quality': sleepQuality,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
