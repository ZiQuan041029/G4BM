const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/User');


// --- PATCH: Update Profile Field ---
router.patch('/update/:id', async (req, res) => {
    try {
        // THE FIX: Use returnDocument: 'after' to satisfy the warning
        // and ensure the update actually happens
        const updatedUser = await User.findByIdAndUpdate(
            req.params.id,
            { $set: req.body }, 
            { returnDocument: 'after' } 
        );

        if (!updatedUser) {
            return res.status(404).json({ message: "User not found" });
        }

        console.log("Database updated for user:", updatedUser._id);
        res.status(200).json(updatedUser);
    } catch (err) {
        console.error("Update Error:", err.message);
        res.status(500).json({ message: "Update failed", error: err.message });
    }
});

// --- POST: Login (Updated to use Model) ---
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await User.findOne({ email });
        if (!user) return res.status(401).json({ message: "Invalid credentials" });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(401).json({ message: "Invalid credentials" });

        const userData = user.toObject();
        delete userData.password;
        userData.userId = user._id.toString();
        res.status(200).json(userData);
    } catch (error) {
        res.status(500).json({ message: "Server error", error: error.message });
    }
});

// --- POST: Register New User ---
router.post('/register', async (req, res) => {
  try {
    // 1. Double check if the email actually exists
    const cleanEmail = req.body.email.trim();
    const emailRegex = new RegExp('^' + cleanEmail + '$', 'i');
    
    const existingUser = await User.findOne({ email: emailRegex });
    if (existingUser) {
      return res.status(400).json({ message: "Email already in use." });
    }

    // 2. Securely hash the plain text password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(req.body.password, salt);

    // 3. Create the user using your Mongoose Model
    const newUser = new User({
      name: req.body.name || "Unknown",
      username: req.body.username || "@username",
      email: cleanEmail, // Save the clean lowercase email
      phone: req.body.phone || "Not provided",
      location: req.body.location || "Malaysia",
      gender: req.body.gender || "Not specified",
      dob: req.body.dob || "DD-MM-YYYY",
      role: req.body.role || "Mama", 
      goal: req.body.goal || "Not specified", 
      password: hashedPassword,
      consent: req.body.consent || true,
      profileImage: req.body.profileImage || null,
      bzPoints: 0,
      lastCheckInDate: "",
      dailyProgress: {
        hasLoggedMoodAndSleep: false,
        hasCompletedSchedule: false,
        hasInteractedWithCommunity: false
      } 
    });

    // 4. Save via Mongoose!
    const savedUser = await newUser.save();

    // 5. Success!
    res.status(201).json({ userId: savedUser._id.toString() });

  } catch (error) {
    console.error("Registration Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// 1. GENERATE MOCK OTP
router.post('/forgot-password', async (req, res) => {
  console.log("--> Forgot Password requested for:", req.body.email);
  try {
    if (!req.body.email) return res.status(400).json({ message: "Email is required" });

    // THE FIX: Clean the email and make the search case-insensitive
    const cleanEmail = req.body.email.trim();
    const emailRegex = new RegExp('^' + cleanEmail + '$', 'i');

    const user = await User.findOne({ email: emailRegex });
    
    if (!user) {
      console.log("--> User not found in DB");
      return res.status(404).json({ message: "User not found" });
    }

    // Generate a random 4-digit code (e.g., "4921")
    const code = Math.floor(1000 + Math.random() * 9000).toString();
    
    user.resetCode = code;
    await user.save(); // This will work perfectly as long as the user passes Mongoose validation

    console.log("--> Code generated:", code);
    res.status(200).json({ message: "Code generated", devCode: code });
  } catch (err) {
    console.error("Forgot Password Error:", err);
    res.status(500).json({ error: err.message });
  }
});

// 2. VERIFY OTP & RESET PASSWORD
router.post('/reset-password', async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;
    
    // THE FIX: Apply the same case-insensitive search here!
    const cleanEmail = email.trim();
    const emailRegex = new RegExp('^' + cleanEmail + '$', 'i');

    // Find user with matching email AND matching code
    const user = await User.findOne({ email: emailRegex, resetCode: code });
    if (!user) return res.status(400).json({ message: "Invalid code or email" });

    // Hash the new password before saving
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(newPassword, salt);
    
    // Clear the code so it can't be used again
    user.resetCode = null; 
    await user.save();

    res.status(200).json({ message: "Password reset successful" });
  } catch (err) {
    console.error("Reset Password Error:", err);
    res.status(500).json({ error: err.message });
  }
});
module.exports = router;