const express = require('express');
const router = express.Router();
const exploreController = require('../controllers/explore.controller');
const { protect } = require('../middleware/auth.middleware');

// Protect all explore routes
router.use(protect);

// Get explore recommendations
router.get('/places', exploreController.getExplorePlaces);

module.exports = router;
