const mongoose = require("mongoose");

const ChatSessionSchema = new mongoose.Schema({
    userId: { type: String, required: true },
    recommendationTriggered: { type: Boolean, default: false },
    lastActivity: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports =
    mongoose.models.ChatSession ||
    mongoose.model("ChatSession", ChatSessionSchema);