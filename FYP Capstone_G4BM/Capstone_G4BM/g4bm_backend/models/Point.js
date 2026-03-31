const mongoose = require('mongoose');

const PointSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  amount: { type: Number, required: true },
  title: { type: String, required: true },
  earnedAt: { type: String, required: true },
  expiresAt: { type: String }, 
});

module.exports = mongoose.model('Point', PointSchema, 'points');