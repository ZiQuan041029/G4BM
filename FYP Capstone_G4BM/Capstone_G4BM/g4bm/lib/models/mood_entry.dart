class MoodEntry {
  final String?
  id; // Maps to MongoDB's _id 
  final String userId;
  final String logDate; // "YYYY-MM-DD" format
  final int moodValue; // 1 to 5 scale
  final String? moodText;
  final double sentimentScore; // AI sentiment
  final String emotionalLabel;
  final List<String>? tags;
  final DateTime createdAt;

  MoodEntry({
    this.id,
    required this.userId,
    required this.logDate,
    required this.moodValue,
    this.moodText,
    required this.sentimentScore,
    required this.emotionalLabel,
    this.tags,
    required this.createdAt,
  });

  // 1. Convert JSON from MongoDB into a Dart Object
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['_id']?.toString(), // Safely parse the MongoDB _id
      userId: json['user_id'] ?? '',
      logDate: json['log_date'] ?? '',
      moodValue: json['mood_value'] ?? 3,
      moodText: json['mood_text'],
      // Convert integers/doubles safely
      sentimentScore: (json['sentiment_score'] ?? 0.0).toDouble(),
      emotionalLabel: json['emotional_label'] ?? 'Neutral',
      // Safely convert JSON array to Dart List<String>
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      // Parse the ISO-8601 date string back into a Dart DateTime
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  // 2. Convert Dart Object back into JSON to send to MongoDB
  Map<String, dynamic> toJson() {
    return {
      // Don't send '_id' if we are creating a new entry, let MongoDB generate it
      if (id != null) '_id': id,
      'user_id': userId,
      'log_date': logDate,
      'mood_value': moodValue,
      'mood_text': moodText,
      'sentiment_score': sentimentScore,
      'emotional_label': emotionalLabel,
      'tags': tags,
      // Convert Dart DateTime to string for the database
      'created_at': createdAt.toIso8601String(),
    };
  }
}
