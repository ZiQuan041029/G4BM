const express = require('express');
const router = express.Router();
const Progress = require('../models/Progress'); 
const Point = require('../models/Point'); // Ensure this model exists!
const mongoose = require('mongoose');

// 1. GET Point History
router.get('/:userId', async (req, res) => {
  try {
    // Instead of db.collection, use the Point model
    const history = await Point.find({ userId: req.params.userId }).sort({ earnedAt: -1 });
    res.status(200).json(history);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 2. ADD Point Transaction
router.post('/add', async (req, res) => {
  try {
    const { userId, amount, title, expiresAt, earnedAt } = req.body;
    const amt = Number(amount);

    // 1. Save to Point History using the Model
    const newPoint = new Point({
      userId,
      amount: amt,
      title,
      earnedAt: earnedAt || new Date().toISOString(),
      expiresAt: expiresAt || null
    });
    await newPoint.save();

    // 2. Update Total in Progress Model
    let progress = await Progress.findOne({ userId });

    if (!progress) {
      progress = new Progress({ userId, bzPoints: 0 });
    }

    progress.bzPoints += amt;
    await progress.save();

    res.status(201).json({ success: true, newTotal: updatedProgress.bzPoints });
  } catch (error) {
    console.error("Error in /points/add:", error);
    res.status(500).json({ error: error.message });
  }

  const existing = await Point.findOne({
    userId,
    title,
    earnedAt
  });

  if (existing) {
    return res.status(400).json({ message: "Reward already given today" });
  }
});

module.exports = router;