require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');


// Import your routes
const moodRoutes = require('./routes/moodRoutes');
const sleepRoutes = require('./routes/sleepRoutes');
const userRoutes = require('./routes/userRoutes');
const routineRoutes = require('./routes/routineRoutes');
const progressRoutes = require('./routes/progressRoutes');
const pointRoutes = require('./routes/pointRoutes');
const familyRoutes = require('./routes/familyRoutes');
const postRoutes = require('./routes/postRoutes');
const aiChatRoutes = require('./routes/aiChatRoutes');
const voiceChatRoutes = require('./routes/voiceChatRoutes');

const app = express();

// Middleware
app.use(cors());
app.use(express.json()); // Allows our server to read JSON from Flutter
app.use(express.urlencoded({ extended: true }));
app.use(express.json({ limit: '50mb' })); 
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Connected to MongoDB Atlas (G4BM_Database)'))
  .catch((err) => console.error('❌ MongoDB connection error:', err));

// Use the routes
app.use('/api/moods', moodRoutes);
app.use('/api/sleep', sleepRoutes);
app.use('/api/users', userRoutes);
app.use('/api/routines', routineRoutes);
app.use('/api/progress', progressRoutes);
app.use('/api/points', pointRoutes);
app.use('/api/family', familyRoutes);
app.use('/api/posts', postRoutes);
app.use('/uploads', express.static('uploads'));
app.use('/api/ai', aiChatRoutes);
app.use("/api/voice-chat", voiceChatRoutes);
app.use('/uploads', express.static('uploads'));

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT,() => {
  console.log(`🚀 G4BM Server is running on http://localhost:${PORT}`);
});