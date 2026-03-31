const express = require("express");
const cors = require("cors");
require("dotenv").config();
const mongoose = require("mongoose");
const multer = require("multer");
const fs = require("fs");
const upload = multer({ dest: "uploads/" });

const { detectMood } = require("./services/moodService");
const { generateRecommendation } = require("./services/aiRecommendationService");
const { calculateDistressScore } = require("./services/distressService");
const { checkEmergency } = require("./services/emergencyService");
const MoodLog = require("./models/moodLog");
const ChatSession = require("./models/ChatSession");
const { moderateContent } = require("./services/moderationService");
const { chatWithAI, processVoiceInput } = require("./services/aiService");

const app = express();

app.use(cors());
app.use(express.json());

/* ---------------- DATABASE ---------------- */

mongoose.connect(process.env.MONGO_URI)
.then(()=> console.log("MongoDB Connected"))
.catch(err=> console.log(err));


/* ---------------- CHATBOT API ---------------- */
app.post("/chat", async (req, res) => {
    try {
        const { userId, message, time } = req.body;

        if (!userId || !message) {
            return res.status(400).json({ error: "Missing userId or message" });
        }

        const FIVE_MINUTES = 5 * 60 * 1000; // 5 minutes in ms
        const now = Date.now();

        // 1️⃣ Find the most recent session
        let session = await ChatSession.findOne({ userId }).sort({ lastActivity: -1 });

        // 2️⃣ Determine if the session is expired
        if (!session || now - session.lastActivity.getTime() > FIVE_MINUTES) {
            // Start a new session
            session = await ChatSession.create({ userId });
        }

        // 3️⃣ Update lastActivity timestamp
        session.lastActivity = new Date();
        await session.save();

        // 4️⃣ Chatbot reply
        const reply = await chatWithAI(userId, message);

        // 5️⃣ Mood detection
        const mood = await detectMood(message);

        // 6️⃣ Distress score
        const distressScore = calculateDistressScore(mood, message);

        // 7️⃣ Emergency detection
        let emergency = checkEmergency(userId, distressScore);

        if (distressScore === 1) {
            emergency = {
                action: "trigger_sos",
                helpline: "988",
                message: "Please call or text 988 immediately. You are not alone."
            };
        }

        // 8️⃣ Recommendation (trigger only once per session)
        let recommendation = null;
        if (!session.recommendationTriggered) {
            recommendation = await generateRecommendation(userId, mood, time);
            session.recommendationTriggered = true;
            await session.save();
        }

        // 9️⃣ Save mood log
        await MoodLog.create({
            userId,
            mood,
            distressScore,
            recommendation
        });

        // 10️⃣ Return response
        res.json({ reply, mood, distressScore, emergency, recommendation });

    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Chat processing failed" });
    }
});

/* ---------------- CHATBOT NEW SESSION ---------------- */

app.post("/start-session", async(req,res)=>{

    const { userId } = req.body;

    const session = new ChatSession({
  userId: req.body.userId,
  message: req.body.message
});

    /*(const session = await ChatSession.create({
        userId,
        recommendationTriggered: false
    });*/

    res.json({
        sessionId: session._id
    });

});

/* ---------------- VOICE EMOTION DETECTION ---------------- */

app.post("/voice-emotion", upload.single("audio"), (req,res)=>{

    const audioFile = req.file;

    const buffer = fs.readFileSync(audioFile.path);

    const mood = detectVoiceEmotion(buffer);

    res.json({
        detectedMood: mood
    });

});

/* ---------------- VOICE CHAT WITH AI ---------------- */

/* ---------------- VOICE CHAT WITH AI (FIXED) ---------------- */
app.post("/voice-chat/:userId", upload.single("audio"), async (req, res) => {
    let tempPath = req.file ? req.file.path : null;
    try {
        const { userId } = req.params;
        if (!tempPath) return res.status(400).json({ error: "No audio file" });

        const buffer = fs.readFileSync(tempPath);

        // 1. Gemini Process
        const { text, emotion } = await processVoiceInput(buffer);

        // 2. Session Management (FIXED: Added this block)
        const FIVE_MINUTES = 5 * 60 * 1000;
        let session = await ChatSession.findOne({ userId }).sort({ lastActivity: -1 });
        if (!session || Date.now() - session.lastActivity.getTime() > FIVE_MINUTES) {
            session = await ChatSession.create({ userId });
        }
        session.lastActivity = new Date();

        // 3. AI Reply
        const reply = await chatWithAI(userId, text, emotion);

        // 4. Analytics
        const mood = await detectMood(text);
        let distressScore = calculateDistressScore(mood, text);
        if (emotion === "stressed" && distressScore < 0.8) {
            distressScore += 0.1; 
        }

        // 5. Emergency Check
        let emergency = checkEmergency(userId, distressScore);
        if (distressScore === 1) {
            emergency = {
                action: "trigger_sos",
                helpline: "988",
                message: "Please call or text 988 immediately."
            };
        }

        // 6. Recommendation (Trigger once per session)
        let recommendation = null;
        if (!session.recommendationTriggered) {
            recommendation = await generateRecommendation(userId, mood);
            session.recommendationTriggered = true;
        }
        await session.save(); // Save session changes

        // 7. Save mood log
        await MoodLog.create({ 
            userId, 
            mood, 
            distressScore, 
            recommendation, 
            source: "voice", 
            detectedTone: emotion 
        });

        // 8. Final Response
        res.status(200).json({
            success: true,
            transcribedMessage: text,
            emotion: emotion,
            reply: reply,
            mood: mood,
            distressScore: distressScore,
            emergency,
            recommendation
        });

    } catch (error) {
        console.error("Voice Chat Error:", error);
        res.status(500).json({ success: false, error: "Internal Server Error" });
    } finally {
        // Always delete the file, even if an error occurred
        if (tempPath && fs.existsSync(tempPath)) {
            fs.unlinkSync(tempPath);
        }
    }
});

/* ---------------- MOOD DETECTION ---------------- */

app.post("/detect-mood", async (req, res) => {
    try {
        let { message, userId } = req.body;

        if (!message) {
            return res.status(400).json({
                error: "Text input is missing"
            });
        }

        // fallback userId
        userId = userId || "guest";

        // 1️⃣ Detect mood
        const mood = await detectMood(message);

        // 2️⃣ Calculate distress safely
        const distressScore = calculateDistressScore(mood, message);

        // 3️⃣ Check emergency
        let emergency = checkEmergency(userId, distressScore);

        // Immediate SOS override if distress is max
        if (distressScore === 1) {
            emergency = {
                action: "trigger_sos",
                helpline: "988",
                message: "Please call or text 988 immediately. You are not alone."
            };
        }

        // 4️⃣ Save mood log
        await MoodLog.create({
            userId,
            mood,
            distressScore
        });

        // 5️⃣ Send response (no recommendation)
        res.json({
            reply: `I hear you. Your feelings are valid, and it’s okay to feel ${mood} right now.`,
            mood,
            distressScore,
            emergency
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({
            error: "Mood detection failed"
        });
    }
});


/* ---------------- COMMUNITY SAFETY ---------------- */

// Update the route to handle 'images' (Multipart)
app.post("/community/post", upload.array('images'), async (req, res) => {
    try {
        // req.body will now contain 'caption' and 'topics'
        const { caption } = req.body; 

        if (!caption) {
            return res.status(400).json({ error: "No content provided" });
        }

        // Run your AI Moderation
        const result = await moderateContent(caption);

        if (result === "UNSAFE") {
            return res.status(400).json({
                error: "Post blocked due to unsafe content"
            });
        }

        // If safe, you would normally save to MongoDB here 
        // using req.files (the images) and req.body (the text)

        res.json({ status: "Post accepted" });
    } catch (error) {
        console.error("Moderation Error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

/* ---------------- MOOD TREND ---------------- */
app.get("/mood-trend/:userId", async(req,res)=>{

    const { userId } = req.params;

    const logs = await MoodLog.find({ userId });

    res.json({
        history: logs
    });

});

/* ---------------- SERVER ---------------- */

app.listen(process.env.PORT, ()=>{
    console.log("Server running on port",process.env.PORT);
});