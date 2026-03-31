// models/MoodLog.js
const mongoose = require("mongoose");

const MoodLogSchema = new mongoose.Schema({
    userId: { type: String, required: true },
    mood: { type: String, required: true },
    distressScore: { type: Number, required: true },
    recommendation: { type: String }, // optional
    createdAt: { type: Date, default: Date.now }
});

// Prevent OverwriteModelError
module.exports = mongoose.models.MoodLog || mongoose.model("MoodLog", MoodLogSchema);