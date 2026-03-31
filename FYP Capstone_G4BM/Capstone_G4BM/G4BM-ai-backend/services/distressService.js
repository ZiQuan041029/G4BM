function calculateDistressScore(mood, message) {

    const moodScores = {
        calm: 0.1,
        happy: 0.1,
        neutral: 0.2,
        tired: 0.4,
        annoyed: 0.4,
        worried: 0.6,
        stressed: 0.7,
        frustrated: 0.75,
        overwhelmed: 0.7,
        sad: 0.7,
        angry: 0.8,
        sick: 0.7
    };

    // normalize mood safely
    const normalizedMood = (mood || "neutral").toLowerCase().trim();

    // fallback to 0.3 if mood not found
    let score = typeof moodScores[normalizedMood] === "number" ? moodScores[normalizedMood] : 0.3;

    // make message safe
    const text = (message || "").toLowerCase();

    const crisisKeywords = ["suicide","kill myself","end my life","i want to die"];
    const highDistressKeywords = ["i can't handle","i feel hopeless","i want to give up","i'm breaking down","i can't do this","crying"];
    const mediumDistressKeywords = ["overwhelmed","stressed","panic","anxious","worried"];

    // crisis keywords → immediate 1
    for(const word of crisisKeywords){
        if(text.includes(word)){
            return 1;
        }
    }

    // high distress keywords → +0.2
    for(const word of highDistressKeywords){
        if(text.includes(word)){
            score = Math.min(score + 0.2, 1);
        }
    }

    // medium distress keywords → +0.1
    for(const word of mediumDistressKeywords){
        if(text.includes(word)){
            score = Math.min(score + 0.1, 1);
        }
    }

    // final check: make sure number is valid
    if(isNaN(score)) score = 0;

    return score;
}

module.exports = { calculateDistressScore };