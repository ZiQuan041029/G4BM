const express = require('express');
const router = express.Router();
const Progress = require('../models/Progress'); // Import your new Model
const User = require('../models/User');

// 1. GET TODAY'S PROGRESS
router.get('/today/:userId', async (req, res) => {
  try {
    const localDate = new Date();
    localDate.setHours(localDate.getHours() + 8);
    const today = localDate.toISOString().split('T')[0]; 
    
    let progress = await Progress.findOne({ userId: req.params.userId });
    
    // --- THE FIX: AUTO-CREATE IF MISSING ---
    if (!progress) {
      console.log("--> Creating new Progress document for user:", req.params.userId);
      progress = new Progress({
        userId: req.params.userId,
        bzPoints: 0, // Note: You can sync this with their User collection points if needed
        lastCheckInDate: today,
        alreadyClaimedToday: false,
        dailyProgress: {
          hasLoggedMoodAndSleep: false,
          hasCompletedSchedule: false,
          hasInteractedWithCommunity: false
        }
      });
      await progress.save();
    }

    // Reset daily tasks if a new day
    if (progress.lastCheckInDate !== today) {
       progress.dailyProgress = { 
         hasLoggedMoodAndSleep: false, 
         hasCompletedSchedule: false, 
         hasInteractedWithCommunity: false 
       };
       progress.lastCheckInDate = today;
       progress.alreadyClaimedToday = false;
       await progress.save();
    }

    res.status(200).json({
       bzPoints: progress.bzPoints,
       alreadyClaimedToday: progress.alreadyClaimedToday,
       dailyProgress: progress.dailyProgress
    });

  } catch (err) {
    console.error("Error fetching today's progress:", err);
    res.status(500).json({ error: err.message });
  }
});

// 2. UPDATE A SPECIFIC TASK
router.patch('/update-task/:userId', async (req, res) => {
  try {
    const { taskType } = req.body;

    const allowedTasks = [
      "hasLoggedMoodAndSleep",
      "hasCompletedSchedule",
      "hasInteractedWithCommunity"
    ];

    if (!allowedTasks.includes(taskType)) {
      return res.status(400).json({ message: "Invalid task type" });
    }

    const updateField = `dailyProgress.${taskType}`;

    const progress = await Progress.findOneAndUpdate(
      { userId: req.params.userId },
      { $set: { [updateField]: true } },
      { 
        returnDocument: 'after',     // Fixes the deprecation warning
        upsert: true,                // Auto-creates the document if missing!
        setDefaultsOnInsert: true    // Fills in the missing boolean fields
      } 
    );

    res.status(200).json({
      success: true,
      dailyProgress: progress.dailyProgress
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 3. CLAIM BZPOINTS
// 3. CLAIM BZPOINTS
router.post('/claim/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date().toISOString().split('T')[0]; // ISO format

    const progress = await Progress.findOne({ userId });
    if (!progress) return res.status(404).json({ message: "User not found" });

    // Check if already claimed today
    if (progress.alreadyClaimedToday && progress.lastClaimedDate === today) {
      return res.status(400).json({ message: "Already claimed today" });
    }

    const claimAmount = 5;

    // 1. Update Progress Math
    progress.bzPoints += claimAmount;
    progress.alreadyClaimedToday = true;
    progress.lastClaimedDate = today;

    
    await progress.save();

    // 3. Save to Point History (WITH EXPIRATION DATE)
    const Point = require('../models/Point');
    const expiryDate = new Date();
    expiryDate.setMonth(expiryDate.getMonth() + 6); // Expires in 6 months

    const newPoint = new Point({
      userId,
      amount: claimAmount,
      title: "Daily Task Completion",
      earnedAt: new Date().toISOString(),
      expiresAt: expiryDate.toISOString() // Flutter needs this for the expiring math!
    });
    await newPoint.save();

    // 4. Send the updated data back to Flutter
    res.status(200).json({ 
      success: true, 
      bzPoints: progress.bzPoints, 
      alreadyClaimedToday: true,
      dailyProgress: progress.dailyProgress 
    });

  } catch (error) {
    console.error("Claim Error:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;