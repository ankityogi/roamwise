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
    required: true, // Links the trip to the specific registered user
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
  itinerarySchedule: [itineraryDaySchema], // Array containing day-by-day events
  createdAt: {
    type: Date,
    default: Date.now,
  }
});

module.exports = mongoose.model('Trip', tripSchema);
