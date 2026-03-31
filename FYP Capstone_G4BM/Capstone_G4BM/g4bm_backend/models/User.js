const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    name: { type: String, required: true },
    username: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    phone: { type: String, default: "Not provided" },
    location: { type: String, default: "Malaysia" },
    gender: { type: String, default: "Not specified" },
    dob: { type: String, default: "DD-MM-YYYY" },
    profileImage: { type: String, default: null }, // Stores Base64 string
    role: { type: String, default: "Mama" },
    goal: { type: String, default: "Not specified" },
    bzPoints: { type: Number, default: 0 },
    lastCheckInDate: { type: String, default: "" },
    resetCode: { type: String, default: null }
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema);