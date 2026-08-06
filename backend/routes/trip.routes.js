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

// Delete an itinerary
router.delete('/:id', tripController.deleteTrip);

module.exports = router;
