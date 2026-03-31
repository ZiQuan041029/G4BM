const express = require('express');
const router = express.Router();
const MoodEntry = require('../models/MoodEntry');

// POST: Save a new mood entry from Flutter
router.post('/', async (req, res) => {
  try {
    const newMood = new MoodEntry(req.body);
    const savedMood = await newMood.save();
    res.status(201).json(savedMood);
  } catch (error) {
    res.status(500).json({ message: "Failed to save mood", error: error.message });
  }
});

// GET: Fetch ALL mood entries for a specific user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    // Use .find() to get an array of all history!
    const moods = await MoodEntry.find({ user_id: userId }).sort({ createdAt: 1 });
    res.status(200).json(moods);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

module.exports = router;