const express = require('express');
const router = express.Router();
const Family = require('../models/Family');
const mongoose = require('mongoose');

// Save or Update
router.post('/save', async (req, res) => {
  try {
    const { id, userId, ...data } = req.body;
    
    let queryId;
    if (id && id.length === 24) {
      queryId = new mongoose.Types.ObjectId(id);
    } else {
      queryId = new mongoose.Types.ObjectId();
    }

    // Using { $set: data } ensures nested fields like healthNotes 
    // and arrays like reminders are overwritten with the new versions.
    const member = await Family.findOneAndUpdate(
      { _id: queryId },
      { $set: { userId, ...data } }, 
      { upsert: true, new: true }
    );

    res.status(200).json(member);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get List
router.get('/:userId', async (req, res) => {
  try {
    const members = await Family.find({ userId: req.params.userId }).lean();
    console.log(`Sending ${members.length} members to Flutter`);
    res.status(200).json(members);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await Family.findByIdAndDelete(id);
    if (result) {
      res.status(200).json({ success: true, message: "Member deleted" });
    } else {
      res.status(404).json({ success: false, message: "Member not found" });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;