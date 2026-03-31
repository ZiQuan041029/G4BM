const express = require('express');
const router = express.Router();
const axios = require('axios');

// CHAT WITH AI

// Middleman Backend
router.post('/chat/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { message } = req.body;

    // 1. Ensure the port matches your AI Backend (5000)
    const aiResponse = await axios.post('http://localhost:5001/chat', {
      userId,
      message
    });

    // 2. Map the data correctly based on your PowerShell test
    // Your AI backend sends 'reply', 'mood', and 'recommendation'
    const { reply, mood, recommendation, distressScore } = aiResponse.data;

    res.status(200).json({
      success: true,
      // We wrap this so Flutter's current 'data["aiResponse"]' logic works
      aiResponse: { 
        reply: reply,
        mood: mood,
        recommendation: recommendation,
        distressScore: distressScore
      }
    });

  } catch (error) {
    console.error("Middleman Error:", error.message);
    res.status(500).json({ success: false, error: "AI service failed" });
  }
});

module.exports = router;