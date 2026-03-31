const mongoose = require('mongoose');

const sleepEntrySchema = new mongoose.Schema({
  user_id: { type: String, required: true },
  log_date: { type: String, required: true }, // Format: YYYY-MM-DD (the day they woke up)
  sleep_time: { type: Date, required: true },
  wake_up_time: { type: Date, required: true },
  total_sleep_minutes: { type: Number, required: true },
  sleep_quality: { type: Number, required: true, min: 1, max: 5 },
  created_at: { type: Date, default: Date.now }
});

// Connects this model to the 'sleep_entries' collection in your database
module.exports = mongoose.model('SleepEntry', sleepEntrySchema, 'sleep_entries');