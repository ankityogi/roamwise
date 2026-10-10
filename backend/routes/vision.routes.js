const express = require('express');
const router = express.Router();
const visionController = require('../controllers/vision.controller');
const { protect } = require('../middleware/auth.middleware');

// Protected Vision route
router.post('/analyze', protect, visionController.analyzeImage);

module.exports = router;
