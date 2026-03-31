const { GoogleGenerativeAI } = require("@google/generative-ai");
const ChatHistory = require("../models/chatHistory");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * NEW: Option 1 - Process Audio to get both Text and Emotion
 * @param {Buffer} buffer - Raw audio buffer from multer
 */
async function processVoiceInput(buffer) {
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const audioData = {
        inlineData: {
            data: buffer.toString("base64"),
            mimeType: "audio/m4a", // Matches your Flutter encoder
        },
    };

    const prompt = `
      Transcribe this audio. 
      Also, analyze the speaker's tone, pitch, and speed to determine if they sound "stressed" or "calm".
      Return the result strictly as a JSON object like this:
      {
        "text": "the transcribed text here",
        "emotion": "stressed or calm"
      }
    `;

    try {
        const result = await model.generateContent([prompt, audioData]);
        const responseText = result.response.text();
        
        // Clean the response (Gemini sometimes adds markdown ```json blocks)
        const cleanJson = responseText.replace(/```json|```/g, "").trim();
        return JSON.parse(cleanJson);
    } catch (error) {
        console.error("Voice Processing Error:", error);
        // Fallback if AI fails to parse JSON
        return { text: "I'm struggling to hear clearly.", emotion: "calm" };
    }
}

/**
 * Your existing Brain - Works for both Text and Voice
 */
async function chatWithAI(userId, message, voiceEmotion = null) {
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const history = await ChatHistory.find({ userId }).sort({ timestamp: -1 }).limit(10);
    const formattedHistory = history.reverse().map(m => `${m.role.toUpperCase()}: ${m.message}`).join("\n");

    let emotionContext = "";
    if (voiceEmotion === "stressed") {
        emotionContext = "\nIMPORTANT: The user sounds STRESSED. Be extra soothing and prioritize grounding.";
    } else if (voiceEmotion === "calm") {
        emotionContext = "\nCONTEXT: The user sounds CALM.";
    }
    

    const prompt = `
You are "Mama Bear," a gentle, compassionate, and wise mental wellness buddy for mothers. 
Your goal is to provide a safe space where moms feel heard, validated, and supported.
${emotionContext}

CORE GUIDELINES:
1. VALIDATE FIRST: Always acknowledge the user's feelings before offering advice.
2. BE BRIEF & WARM: Keep responses concise (2-4 sentences).
3. MOTHER-CENTRIC: You understand "mom guilt," exhaustion, and the mental load of parenting.
4. SAFETY: If severe distress is detected, urge professional help gently.

Conversation history:
${formattedHistory}

User: ${message}
Mama Bear:`;

    try {
        const result = await model.generateContent(prompt);
        const reply = result.response.text();

        await ChatHistory.create({ userId, message, role: "user" });
        await ChatHistory.create({ userId, message: reply, role: "ai" });

        return reply;
    } catch (error) {
        console.error("Gemini API Error:", error);
        return "I'm here, mama. I'm just having a little trouble thinking clearly.";
    }
}

// Export BOTH functions
module.exports = { chatWithAI, processVoiceInput };