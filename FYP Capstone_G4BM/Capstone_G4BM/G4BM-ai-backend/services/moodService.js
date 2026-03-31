// services/moodService.js

const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function detectMood(message){

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const prompt = `
You are an emotion classification system.

Classify the emotion of the following message into EXACTLY one of these labels:

happy 
sad
stressed
angry
calm
neutral
annoyed
worried 
overwhelmed
tired
sick
frustrated

Also detect if the message indicates severe distress.

Rules:
- Respond with ONLY one word
- Do not explain
- Do not add punctuation

Message: ${message}
`;

    const result = await model.generateContent(prompt);

    let mood = await result.response.text();

    mood = mood.trim().toLowerCase();

    return mood;

}

module.exports = { detectMood };