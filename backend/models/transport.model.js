const mongoose = require('mongoose');

const transportSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  tripId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Trip',
  },
  transportType: {
    type: String,
    enum: ['flight', 'train', 'bus', 'ferry'],
    default: 'flight',
  },
  carrier: {
    type: String,
    required: true, // e.g., 'Emirates', 'Air India', 'SNCF TGV', 'JR Shinkansen'
  },
  carrierCode: {
    type: String, // e.g., 'EK', 'AI', '6E', 'JR'
    default: 'RW',
  },
  transitNumber: {
    type: String,
    required: true, // e.g., 'EK-501', 'TGV-9234'
  },
  bookingReference: {
    type: String,
    required: true, // e.g., 'RW-PNR-7749'
  },
  departure: {
    city: { type: String, required: true },
    code: { type: String, required: true }, // e.g., 'DXB', 'PAR', 'STV'
    terminal: { type: String, default: 'T1' },
    gate: { type: String, default: 'A12' },
    time: { type: Date, required: true },
  },
  arrival: {
    city: { type: String, required: true },
    code: { type: String, required: true }, // e.g., 'CDG', 'HND', 'BOM'
    terminal: { type: String, default: 'T2' },
    gate: { type: String, default: 'B4' },
    time: { type: Date, required: true },
  },
  passengerName: {
    type: String,
    required: true,
  },
  seatNumber: {
    type: String,
    default: '14A',
  },
  seatClass: {
    type: String,
    default: 'Economy Premium',
  },
  status: {
    type: String,
    enum: ['On Time', 'Boarding', 'Delayed', 'Landed', 'Cancelled'],
    default: 'On Time',
  },
  qrCodeData: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Transport', transportSchema);
