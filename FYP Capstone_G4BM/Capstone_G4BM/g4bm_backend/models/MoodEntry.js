const mongoose = require('mongoose');

const moodEntrySchema = new mongoose.Schema({
  user_id: { type: String, required: true },
  log_date: { type: String, required: true }, // Format: YYYY-MM-DD
  mood_value: { type: Number, required: true, min: 1, max: 5 },
  mood_text: { type: String, default: "" },
  sentiment_score: { type: Number, required: true },
  emotional_label: { type: String, required: true },
  tags: [{ type: String }],
  created_at: { type: Date, default: Date.now }
});

// This tells Mongoose to use the "mood_entries" collection in your G4BM_Database
module.exports = mongoose.model('MoodEntry', moodEntrySchema, 'mood_entries');