const mongoose = require('mongoose');

const FamilySchema = new mongoose.Schema({
  userId: { type: String, required: true },
  name: { type: String, required: true },
  relationship: { type: String },
  image: { type: String },
  age: { type: mongoose.Schema.Types.Mixed }, // Mixed allows Number OR String
  gender: { type: String },
  dob: { type: String },
  education: { type: String },
  height: { type: mongoose.Schema.Types.Mixed },
  weight: { type: mongoose.Schema.Types.Mixed },
  healthNotes: { type: String },
  sleepQuality: { type: String },
  physicalLevel: { type: String },
  emotionalState: { type: String },
  socialInteraction: { type: String },
  learningFocus: { type: String },
  screenTime: { type: String },
  outdoorActivity: { type: String },
  eatingHabits: { type: String },
  reminders: [
    {
      title: { type: String },
    isDone: { type: Boolean, default: false },
    completedAt: { type: String }
    }
  ]
}, { timestamps: true });

module.exports = mongoose.model('Family', FamilySchema, 'family');