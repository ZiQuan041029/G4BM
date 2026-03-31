const mongoose = require('mongoose');

const progressSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  bzPoints: { type: Number, default: 0 },
  alreadyClaimedToday: { type: Boolean, default: false },
  
  // THE FIX: Add these string fields so Mongoose saves your dates!
  lastCheckInDate: { type: String, default: "" }, 
  lastClaimedDate: { type: String, default: "" },

  dailyProgress: {
    hasLoggedMoodAndSleep: { type: Boolean, default: false },
    hasCompletedSchedule: { type: Boolean, default: false },
    hasInteractedWithCommunity: { type: Boolean, default: false }
  }
});

module.exports = mongoose.model('Progress', progressSchema);