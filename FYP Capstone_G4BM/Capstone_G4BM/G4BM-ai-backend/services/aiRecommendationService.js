const { GoogleGenerativeAI } = require("@google/generative-ai");
const MoodLog = require("../models/moodLog");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function generateRecommendation(userId, mood, time) {
    // Fetch recent mood history
    const history = await MoodLog.find({ userId })
        .sort({ createdAt: -1 })
        .limit(5);

    const lastRecommendations = history.map(h => h.recommendation).filter(Boolean);
    const moodTrend = history.map(h => h.mood).join(", ") || "none";
    const isNewUser = history.length === 0;

    // AI prompt
    const prompt = `
You are a supportive mental wellness assistant.

User info:
- Current mood: ${mood}
- Available time: ${time} minutes
- Recent moods in past 5 days: ${isNewUser ? "none" : moodTrend}
- Previous AI recommendations: ${isNewUser ? "none" : lastRecommendations.join("; ")}

Suggest THREE new, varied self-care activities for mothers.
Rules:
- Activities must not repeat previous recommendations
- Each activity must be different
- Fit within the available time
- Categories: mindfulness, movement, creativity, reflection, social connection
- Tone: supportive, warm, and empathetic
- Respond in format:
1. Title
Short description
2. Title
Short description
3. Title
Short description
`;

    let suggestion;

    try {
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
        const result = await model.generateContent(prompt);
        suggestion = (await result.response.text()).trim();
    } catch (error) {
        console.error("Gemini AI recommendation error:", error);
        // Fallback for AI failure
        suggestion = `
1. 3-Minute Breathing: Focus on your breath to calm your mind.
2. Gratitude Note: Write down one thing you're thankful for.
3. Gentle Stretch: Loosen your shoulders and neck muscles.
        `.trim();
    }

    // Log the recommendation for history
    await MoodLog.create({
        userId,
        mood,
        recommendation: suggestion,
        distressScore: 0 // optional
    });

    return suggestion;
}

module.exports = { generateRecommendation };