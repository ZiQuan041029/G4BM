// routes/routineRoutes.js
const express = require('express');
const router = express.Router();
const Routine = require('../models/Routine');

// 1. CREATE or UPDATE a routine (Upsert)
// We use Upsert so if the task already exists, it updates it. If not, it creates it.
router.post('/', async (req, res) => {
  try {
    // Look at all these beautiful, clean variable names!
    const { 
      userId, taskId, type, taskName, date, time, duration, 
      isReminder, status, fullDateTime, iconCodePoint, iconString
    } = req.body;

    const savedRoutine = await Routine.findOneAndUpdate(
      { taskId: taskId }, 
      {
        userId, taskId, type, taskName, date, time, duration, 
        isReminder, status, fullDateTime, iconCodePoint, iconString
      },
      { new: true, upsert: true } 
    );

    res.status(200).json({ message: "Saved successfully", routine: savedRoutine });
  } catch (error) {
    console.error("Error saving routine:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// 2. GET all routines for a specific user
router.get('/:userId', async (req, res) => {
  try {
    const routines = await Routine.find({ userId: req.params.userId }).sort({ fullDateTime: 1 });
    res.status(200).json(routines);
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

// 3. DELETE a routine
router.delete('/:taskId', async (req, res) => {
  try {
    await Routine.findOneAndDelete({ taskId: req.params.taskId });
    res.status(200).json({ message: "Routine deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;