const express = require('express');
const router = express.Router();
const {
  createBooking,
  getMyBookings,
  getBookingById,
  cancelBooking,
} = require('../controllers/booking.controller');
const { protect } = require('../middleware/auth.middleware');

// All booking operations require valid user authentication
router.use(protect);

// Create new reservation
// URL: POST /api/bookings
router.post('/', createBooking);

// Get current user's reservations
// URL: GET /api/bookings/my-bookings
router.get('/my-bookings', getMyBookings);

// Get specific reservation details
// URL: GET /api/bookings/:id
router.get('/:id', getBookingById);

// Cancel a reservation
// URL: POST /api/bookings/:id/cancel
router.post('/:id/cancel', cancelBooking);

module.exports = router;
