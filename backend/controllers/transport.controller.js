const Transport = require('../models/transport.model');

// Helper to generate realistic PNR reference
const generatePNR = () => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let pnr = 'RW-';
  for (let i = 0; i < 6; i++) {
    pnr += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return pnr;
};

/**
 * Fetch all transport tickets for the authenticated user
 */
exports.getTransports = async (req, res) => {
  try {
    const userId = req.user._id;
    let transports = await Transport.find({ userId }).sort({ 'departure.time': 1 });

    // Seed realistic mock flight/train if none exist so user has immediate demo data
    if (transports.length === 0) {
      const now = new Date();
      const depDate = new Date(now.getTime() + 1000 * 60 * 60 * 24 * 2); // 2 days later
      const arrDate = new Date(depDate.getTime() + 1000 * 60 * 60 * 7); // 7 hours flight

      const sampleFlight = new Transport({
        userId,
        transportType: 'flight',
        carrier: 'Emirates Airlines',
        carrierCode: 'EK',
        transitNumber: 'EK-501',
        bookingReference: generatePNR(),
        passengerName: req.user.name || 'Alex Morgan',
        departure: {
          city: 'Dubai',
          code: 'DXB',
          terminal: 'Terminal 3',
          gate: 'B22',
          time: depDate,
        },
        arrival: {
          city: 'Paris Charles de Gaulle',
          code: 'CDG',
          terminal: 'Terminal 2E',
          gate: 'K34',
          time: arrDate,
        },
        seatNumber: '12K',
        seatClass: 'Business Club',
        status: 'On Time',
        qrCodeData: `M1MORGAN/ALEX       E${generatePNR()} DXBCDGEK 0501 245Y012K0023 100`,
      });

      const trainDep = new Date(arrDate.getTime() + 1000 * 60 * 60 * 24);
      const trainArr = new Date(trainDep.getTime() + 1000 * 60 * 60 * 2.5);

      const sampleTrain = new Transport({
        userId,
        transportType: 'train',
        carrier: 'SNCF TGV INOUI',
        carrierCode: 'SNCF',
        transitNumber: 'TGV-6612',
        bookingReference: generatePNR(),
        passengerName: req.user.name || 'Alex Morgan',
        departure: {
          city: 'Paris Gare de Lyon',
          code: 'PAR-GL',
          terminal: 'Hall 1',
          gate: 'Track 8',
          time: trainDep,
        },
        arrival: {
          city: 'Lyon Part-Dieu',
          code: 'LYS-PD',
          terminal: 'Main Concourse',
          gate: 'Track A',
          time: trainArr,
        },
        seatNumber: 'Car 4 / Seat 42',
        seatClass: 'First Class Quiet Zone',
        status: 'On Time',
        qrCodeData: `TGV-SNCF-6612-${generatePNR()}-PAR-LYS`,
      });

      await sampleFlight.save();
      await sampleTrain.save();
      transports = [sampleFlight, sampleTrain];
    }

    res.status(200).json(transports);
  } catch (error) {
    console.error('Fetch Transports Error:', error);
    res.status(500).json({ message: 'Failed to fetch transport tickets.', error: error.message });
  }
};

/**
 * Create a new transport booking / ticket
 */
exports.createTransport = async (req, res) => {
  try {
    const userId = req.user._id;
    const {
      transportType,
      carrier,
      carrierCode,
      transitNumber,
      departureCity,
      departureCode,
      departureTerminal,
      departureGate,
      departureTime,
      arrivalCity,
      arrivalCode,
      arrivalTerminal,
      arrivalGate,
      arrivalTime,
      passengerName,
      seatNumber,
      seatClass,
      tripId,
    } = req.body;

    if (!carrier || !transitNumber || !departureCity || !arrivalCity) {
      return res.status(400).json({ message: 'Carrier, transit number, and departure/arrival cities are required.' });
    }

    const bookingReference = req.body.bookingReference || generatePNR();
    const qrCodeData = `RW-TRANS-${transitNumber}-${bookingReference}-${Date.now()}`;

    const transport = new Transport({
      userId,
      tripId: tripId || null,
      transportType: transportType || 'flight',
      carrier,
      carrierCode: carrierCode || 'RW',
      transitNumber,
      bookingReference,
      passengerName: passengerName || req.user.name || 'Traveler',
      departure: {
        city: departureCity,
        code: departureCode || departureCity.substring(0, 3).toUpperCase(),
        terminal: departureTerminal || 'T1',
        gate: departureGate || 'A1',
        time: departureTime ? new Date(departureTime) : new Date(Date.now() + 86400000),
      },
      arrival: {
        city: arrivalCity,
        code: arrivalCode || arrivalCity.substring(0, 3).toUpperCase(),
        terminal: arrivalTerminal || 'T2',
        gate: arrivalGate || 'B2',
        time: arrivalTime ? new Date(arrivalTime) : new Date(Date.now() + 86400000 + 7200000),
      },
      seatNumber: seatNumber || '14A',
      seatClass: seatClass || 'Economy',
      status: 'On Time',
      qrCodeData,
    });

    await transport.save();
    res.status(201).json(transport);
  } catch (error) {
    console.error('Create Transport Error:', error);
    res.status(500).json({ message: 'Failed to create transport ticket.', error: error.message });
  }
};

/**
 * Simulate live status lookup / gate update
 */
exports.lookupLiveStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const transport = await Transport.findOne({ _id: id, userId: req.user._id });
    if (!transport) {
      return res.status(404).json({ message: 'Ticket not found.' });
    }

    const statuses = ['On Time', 'Boarding', 'Delayed 15m', 'Gate Changed'];
    const randomStatus = statuses[Math.floor(Math.random() * statuses.length)];
    if (randomStatus === 'Delayed 15m') {
      transport.status = 'Delayed';
    } else if (randomStatus === 'Gate Changed') {
      transport.departure.gate = `C${Math.floor(Math.random() * 20) + 1}`;
    } else {
      transport.status = randomStatus;
    }

    await transport.save();
    res.status(200).json({ transport, updateMessage: `Live refresh: Status updated to ${transport.status} (Gate ${transport.departure.gate})` });
  } catch (error) {
    console.error('Lookup Live Status Error:', error);
    res.status(500).json({ message: 'Failed to lookup live status.', error: error.message });
  }
};

/**
 * Delete a transport ticket
 */
exports.deleteTransport = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Transport.findOneAndDelete({ _id: id, userId: req.user._id });
    if (!deleted) {
      return res.status(404).json({ message: 'Ticket not found.' });
    }
    res.status(200).json({ message: 'Transport ticket deleted successfully.' });
  } catch (error) {
    console.error('Delete Transport Error:', error);
    res.status(500).json({ message: 'Failed to delete transport ticket.', error: error.message });
  }
};
