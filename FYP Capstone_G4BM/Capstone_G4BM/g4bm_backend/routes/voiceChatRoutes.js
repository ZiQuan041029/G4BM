const express = require('express');
const router = express.Router();
const multer = require('multer');
const fs = require('fs');
const axios = require('axios');
const FormData = require('form-data'); // Recommended for sending files between servers

const upload = multer({ dest: 'uploads/' });

/**
 * POST /api/voice-chat/:userId
 * Receives .m4a from Flutter -> Forwards to AI Backend
 */
router.post('/:userId', upload.single('audio'), async (req, res) => {
    const tempPath = req.file ? req.file.path : null;
    
    try {
        const { userId } = req.params;

        if (!tempPath) {
            return res.status(400).json({ success: false, error: "No audio file uploaded" });
        }

        // 1️⃣ PREPARE FORM DATA TO SEND TO AI BACKEND
        // We send the actual file stream so the AI Backend can read it properly
        const form = new FormData();
        const fileStream = fs.createReadStream(tempPath); // Create the stream as a variable
        form.append('audio', fileStream);

        // 2️⃣ FORWARD TO AI BACKEND (Port 5001)
        // Note: We use the /voice-chat/:userId route on the AI Backend
        const aiResponse = await axios.post(
            `http://localhost:5001/voice-chat/${userId}`, 
            form,
            { headers: { ...form.getHeaders() } }
        );

        // 3️⃣ CLEAN UP TEMP FILE
        // Ensure the stream is destroyed before unlinking
            fileStream.destroy(); 

            if (fs.existsSync(tempPath)) {
                fs.unlinkSync(tempPath);
            }

        // 4️⃣ RETURN AI BACKEND'S RESPONSE TO FLUTTER
        // This includes transcribedMessage, reply, emotion, mood, etc.
        return res.status(200).json(aiResponse.data);

    } catch (error) {
        console.error("❌ Middleman Error:", error.response?.data || error.message);
        
        if (tempPath && fs.existsSync(tempPath)) {
            fs.unlinkSync(tempPath);
        }

        res.status(500).json({
            success: false,
            error: "Voice relay failed",
            details: error.message
        });
    }
});

module.exports = router;