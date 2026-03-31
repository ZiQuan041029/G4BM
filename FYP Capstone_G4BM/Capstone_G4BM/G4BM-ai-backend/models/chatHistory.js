const mongoose = require("mongoose");

const ChatSchema = new mongoose.Schema({

    userId: String,

    message: String,

    role: String, // user or ai

    timestamp: {
        type: Date,
        default: Date.now
    }

});

module.exports = mongoose.model("ChatHistory", ChatSchema);