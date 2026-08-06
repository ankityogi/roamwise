const express = require('express');
const router = express.Router();
const {
  registerUser,
  loginUser,
  getUserProfile,
} = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth.middleware');

// Public route to register a new user account
// URL: POST /api/auth/register
router.post('/register', registerUser);

// Public route to authenticate an existing user
// URL: POST /api/auth/login
router.post('/login', loginUser);

// Protected route to fetch profile details of current logged-in user
// URL: GET /api/auth/profile
router.get('/profile', protect, getUserProfile);

module.exports = router;
