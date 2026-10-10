const mongoose = require('mongoose');

// Define the User Schema representing user entity details stored in MongoDB
const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide your full name'],
    trim: true,
  },
  email: {
    type: String,
    required: [true, 'Please provide your email address'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please fill a valid email address',
    ],
  },
  password: {
    type: String,
    required: function () {
      return this.authProvider === 'local';
    },
    minlength: [6, 'Password must be at least 6 characters long'],
  },
  googleId: {
    type: String,
    sparse: true,
    unique: true,
  },
  authProvider: {
    type: String,
    enum: ['local', 'google'],
    default: 'local',
  },
  profilePic: {
    type: String,
    default: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80', // Default placeholder avatar
  },
  travelStats: {
    tripsCount: { type: Number, default: 0 },
    countriesCount: { type: Number, default: 0 },
    savedItemsCount: { type: Number, default: 0 },
  },
  emergencyContacts: [
    {
      name: { type: String, trim: true },
      phone: { type: String, trim: true },
    }
  ],
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('User', userSchema);
