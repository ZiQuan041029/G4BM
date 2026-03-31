const DISTRESS_THRESHOLD = 0.75;

let lastTrigger = {};

function checkEmergency(userId, distressScore){

    distressScore = Number(distressScore);

    console.log("Distress Score:", distressScore);

    const now = Date.now();
    const cooldown = 120000;

    if(distressScore >= DISTRESS_THRESHOLD){

        if(lastTrigger[userId] && (now - lastTrigger[userId]) < cooldown){

            return {
                action: "supportive_message",
                message: "Take a deep breath. You're not alone."
            };
        }

        lastTrigger[userId] = now;

        return {
            action: "trigger_sos",
            helpline: "1800-HELP-NOW",
            message: "It seems like you're going through a difficult time. You are not alone. Consider reaching out to a trusted person or a helpline."
        };
    }

    return { action: "none" };
}

module.exports = { checkEmergency };