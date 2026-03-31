const mongoose = require('mongoose');

const postSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  userName: { type: String, required: true },
  userImage: { type: String, default: 'assets/default_user_pp.png' },
  content: { type: String, required: true },
  categories: { type: [String], required: true },
  likes: { type: [String], default: [] },
  
  // THE FIX: Add this line so MongoDB accepts your images!
  images: { type: [String], default: [] }, 

  comments: { type: Array, default: [] }
}, { timestamps: true });

module.exports = mongoose.model('Post', postSchema);