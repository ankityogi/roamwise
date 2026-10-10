const express = require('express');
const router = express.Router();
const tripController = require('../controllers/trip.controller');
const { protect } = require('../middleware/auth.middleware');

// Protect all routes within this module
router.use(protect);

// Generate a new itinerary using Gemini
router.post('/generate', tripController.generateItinerary);

// Fetch all saved user itineraries
router.get('/', tripController.getTrips);

// Join a trip using invite code
router.post('/join', tripController.joinTripByCode);

// Add custom event to trip day
router.post('/:tripId/events', tripController.addCustomEvent);

// Toggle upvote on trip event
router.post('/:tripId/events/:eventId/vote', tripController.toggleEventVote);

// Delete an itinerary
router.delete('/:id', tripController.deleteTrip);

module.exports = router;
