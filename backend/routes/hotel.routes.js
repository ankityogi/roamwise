const express = require('express');
const router = express.Router();
const { getHotels, getHotelById } = require('../controllers/hotel.controller');

// Search and list hotels
// URL: GET /api/hotels
router.get('/', getHotels);

// Get specific hotel details
// URL: GET /api/hotels/:id
router.get('/:id', getHotelById);

module.exports = router;
