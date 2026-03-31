const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function moderateContent(text){

    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

    const prompt = `
Check if this message contains harmful, abusive, or unsafe content.

Message: ${text}

Respond only with:
SAFE
UNSAFE
`;

    const result = await model.generateContent(prompt);

    const decision = await result.response.text();

    return decision.trim();

}

module.exports = { moderateContent };