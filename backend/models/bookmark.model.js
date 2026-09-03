const mongoose = require('mongoose');

// Define the Bookmark Schema to persist favorited points of interest linked to a user account
const bookmarkSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: [true, 'Please provide a title for the bookmarked place'],
    trim: true,
  },
  category: {
    type: String,
    required: [true, 'Please provide a category'],
    enum: ['Hotels', 'Dining', 'Sights', 'Transit'],
  },
  rating: {
    type: Number,
    default: 0.0,
  },
  price: {
    type: String,
    default: '$$',
  },
  distance: {
    type: String,
    default: '0.0 km',
  },
  latitude: {
    type: Number,
    required: [true, 'Please provide the latitude coordinates'],
  },
  longitude: {
    type: Number,
    required: [true, 'Please provide the longitude coordinates'],
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Bookmark', bookmarkSchema);
