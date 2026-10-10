const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const authRoutes = require('./routes/auth.routes');
const tripRoutes = require('./routes/trip.routes');
const chatRoutes = require('./routes/chat.routes');
const exploreRoutes = require('./routes/explore.routes');
const bookmarkRoutes = require('./routes/bookmark.routes');
const hotelRoutes = require('./routes/hotel.routes');
const bookingRoutes = require('./routes/booking.routes');
const visionRoutes = require('./routes/vision.routes');
const transportRoutes = require('./routes/transport.routes');
const { apiLimiter, aiGenerationLimiter } = require('./middleware/rateLimiter.middleware');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS
app.use(cors());

// Parse incoming JSON and URL-encoded requests (supports camera image base64 uploads up to 10mb)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Apply general API rate limiter to all /api/ requests (100 req/min)
app.use('/api', apiLimiter);

// DB Connection
connectDB();

// Register Route Handlers
app.use('/api/auth', authRoutes);
app.use('/api/trips', aiGenerationLimiter, tripRoutes);
app.use('/api/chat', aiGenerationLimiter, chatRoutes);
app.use('/api/vision', aiGenerationLimiter, visionRoutes);
app.use('/api/explore', exploreRoutes);
app.use('/api/bookmarks', bookmarkRoutes);
app.use('/api/hotels', hotelRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/transports', transportRoutes);

// Health Check Endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    message: 'RoamWise API server is running smoothly',
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

// Start listening
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = app;
