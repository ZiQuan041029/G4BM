const mongoose = require('mongoose');

const routineSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  taskId: { type: String, required: true, unique: true }, // "task_123"
  
  type: { type: String, required: true }, // "task", "mood", "sleep", etc.
  
  // ---> YOUR IDEAL FIELDS <---
  taskName: { type: String, required: true }, // "Maya's Bath Time"
  date: { type: String, required: true }, // "2026-03-12"
  time: { type: String }, // "18:00"
  duration: { type: Number, default: 0 }, // 30
  isReminder: { type: Boolean, default: false }, // true
  status: { type: String, default: "Pending" }, // "Pending" or "Completed"
  
  // (We keep these for the mood/sleep blocks so they don't crash)
  fullDateTime: { type: Date, required: true },
  iconCodePoint: { type: Number },
  iconString: { type: String },


}, { timestamps: true });

module.exports = mongoose.model('Routine', routineSchema);