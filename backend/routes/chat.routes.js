const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const { protect } = require('../middleware/auth.middleware');

// Protect chatbot assistant routes
router.use(protect);

// Generate travel assistance conversational responses
router.post('/', chatController.chatResponse);

module.exports = router;
