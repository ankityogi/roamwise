const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  bookingReference: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true,
  },
  hotel: {
    id: { type: String },
    title: { type: String, required: true },
    category: { type: String, default: 'Hotels' },
    rating: { type: Number, default: 4.5 },
    location: { type: String, default: '' },
    image: { type: String, default: '' },
  },
  roomType: {
    type: String,
    required: true,
    default: 'Deluxe Room',
  },
  pricePerNight: {
    type: Number,
    required: true,
  },
  numberOfRooms: {
    type: Number,
    default: 1,
    min: 1,
  },
  checkInDate: {
    type: Date,
    required: true,
  },
  checkOutDate: {
    type: Date,
    required: true,
  },
  numberOfNights: {
    type: Number,
    required: true,
    min: 1,
  },
  guests: {
    adults: { type: Number, default: 1, min: 1 },
    children: { type: Number, default: 0, min: 0 },
  },
  contactDetails: {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, trim: true },
    phone: { type: String, default: '', trim: true },
  },
  specialRequests: {
    type: String,
    default: '',
    trim: true,
  },
  pricing: {
    baseTotal: { type: Number, required: true },
    taxAndFees: { type: Number, required: true },
    totalAmount: { type: Number, required: true },
  },
  status: {
    type: String,
    enum: ['confirmed', 'cancelled', 'completed'],
    default: 'confirmed',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Booking', bookingSchema);
