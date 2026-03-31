const express = require('express');
const router = express.Router();
const SleepEntry = require('../models/SleepEntry');

// POST: Save a new sleep schedule from Flutter
router.post('/', async (req, res) => {
  try {
    const newSleep = new SleepEntry(req.body);
    const savedSleep = await newSleep.save();
    res.status(201).json(savedSleep);
  } catch (error) {
    res.status(500).json({ message: "Failed to save sleep entry", error: error.message });
  }
});

// GET: Fetch ALL sleep data for a specific user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    // Use .find() to get an array of all history!
    const sleepData = await SleepEntry.find({ user_id: userId }).sort({ createdAt: 1 });
    res.status(200).json(sleepData);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

module.exports = router;