const mongoose = require('mongoose');

// Schema for individual timeline events within a travel day
const timelineEventSchema = new mongoose.Schema({
  time: {
    type: String,
    required: true, // e.g., '10:00 AM'
  },
  title: {
    type: String,
    required: true, // e.g., 'Arrival & Check-in'
  },
  description: {
    type: String,
    required: true, // e.g., 'Check in to accommodation and rest'
  },
  votes: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  addedBy: {
    type: String, // name of creator/collaborator
    default: 'AI Assistant',
  },
  latitude: {
    type: Number,
  },
  longitude: {
    type: Number,
  }
});

// Schema for a single day of travel itinerary
const itineraryDaySchema = new mongoose.Schema({
  dayNumber: {
    type: Number,
    required: true, // e.g., 1, 2, 3...
  },
  events: [timelineEventSchema] // List of activities scheduled on this day
});

// Primary Schema representing a generated trip itinerary
const tripSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true, // Owner who created the trip
  },
  title: {
    type: String,
    required: true, // e.g., 'Kyoto Exploration'
  },
  destination: {
    type: String,
    required: true, // e.g., 'Kyoto, Japan'
  },
  dates: {
    type: String,
    default: 'TBD (Planned)', // e.g., 'Aug 15 - Aug 22, 2026' or placeholder
  },
  daysCount: {
    type: Number,
    required: true, // Duration of the trip
  },
  travelStyle: {
    type: String,
    required: true, // e.g., 'Cultural', 'Adventure', 'Leisure'
  },
  inviteCode: {
    type: String,
    unique: true,
    sparse: true,
    uppercase: true,
    trim: true,
  },
  collaborators: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    name: {
      type: String,
    },
    email: {
      type: String,
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    }
  }],
  itinerarySchedule: [itineraryDaySchema], // Array containing day-by-day events
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('Trip', tripSchema);
