const express = require('express');
const router = express.Router();
const Post = require('../models/Post'); 
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { moderateContent } = require('../services/moderationService');


// 1. Setup Upload Directory
const uploadDir = 'uploads/';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// 2. Multer Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage });

/* -----------------------------------------------------------
   CREATE POST (With Gemini Moderation & Image Support)
----------------------------------------------------------- */
router.post('/create', upload.array('images', 4), async (req, res) => {
  try {
    // 1. Safely extract all text fields from Flutter
    const { content, userId, userName, userImage, categories } = req.body;

    // 2. AI Moderation Check (Only runs if content exists)
    if (content && content.trim().length > 0) {
      const result = await moderateContent(content);
      if (result === "UNSAFE") {
        return res.status(400).json({ 
          error: "Post blocked due to unsafe content" 
        });
      }
    }

    // 3. Category Parsing
    let parsedCategories = [];
    if (categories) {
      try {
        parsedCategories = JSON.parse(categories);
      } catch (e) {
        parsedCategories = categories.split(',').map(s => s.trim());
      }
    }

    // 4. Image Handling (This safely handles when 0 images are sent!)
    const files = req.files || [];
    const imagePaths = files.map(file => {
      return `http://localhost:3000/uploads/${file.filename}`;
    });

    // 5. Build and Save to MongoDB
    const newPost = new Post({
      userId: userId,
      userName: userName,
      userImage: userImage,
      content: content || "", // Failsafe prevents undefined crashes
      categories: parsedCategories,
      images: imagePaths,
    });

    const savedPost = await newPost.save();
    res.status(201).json(savedPost);

  } catch (err) {
    console.error("Creation Error:", err);
    res.status(500).json({ error: err.message });
  }
});

/* -----------------------------------------------------------
   GET POSTS (With Category Filter)
----------------------------------------------------------- */
router.get('/', async (req, res) => {
  try {
    const { category } = req.query;
    let filter = {};

    if (category && category !== 'For you') {
      filter = { categories: category }; 
    }

    const posts = await Post.find(filter).sort({ createdAt: -1 });
    res.status(200).json(posts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/* -----------------------------------------------------------
   INTERACTIONS (Comments, Likes, Delete)
----------------------------------------------------------- */

// Add Comment
router.post('/:postId/comment', async (req, res) => {
  try {
    const post = await Post.findByIdAndUpdate(
      req.params.postId,
      { $push: { comments: req.body } },
      { new: true }
    );
    if (!post) return res.status(404).json({ message: "Post not found" });
    res.status(200).json(post);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- TOGGLE LIKE ROUTE ---
// Matches: PATCH /api/posts/:id/like
router.patch('/:id/like', async (req, res) => {
  try {
    const { userId } = req.body;
    const post = await Post.findById(req.params.id);
    
    if (!post) return res.status(404).json({ message: "Post not found" });

    // Check if user already liked it
    const index = post.likes.indexOf(userId);
    if (index === -1) {
      post.likes.push(userId); // Add Like
    } else {
      post.likes.splice(index, 1); // Remove Like
    }

    await post.save();
    res.status(200).json(post);
  } catch (error) {
    console.error("Like Error:", error);
    res.status(500).json({ message: "Server error toggling like" });
  }
});

// --- DELETE POST ROUTE ---
// Matches: DELETE /api/posts/:id
router.delete('/:id', async (req, res) => {
  console.log("--> DELETE ROUTE HIT FOR ID:", req.params.id);
  try {
    const deletedPost = await Post.findByIdAndDelete(req.params.id);
    if (!deletedPost) {
      return res.status(404).json({ message: "Post not found in database" });
    }
    res.status(200).json({ message: "Post deleted successfully" });
  } catch (error) {
    console.error("Delete Error:", error);
    res.status(500).json({ message: "Server error deleting post" });
  }
});



module.exports = router;