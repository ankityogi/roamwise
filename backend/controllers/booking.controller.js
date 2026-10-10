const Booking = require('../models/booking.model');
const User = require('../models/user.model');

/**
 * Generate a clean booking reference code
 * Example: RW-HTL-749214
 */
const generateBookingReference = () => {
  const randomNum = Math.floor(100000 + Math.random() * 900000);
  return `RW-HTL-${randomNum}`;
};

/**
 * Create a new hotel booking
 * ROUTE: POST /api/bookings
 * Requires authentication
 */
exports.createBooking = async (req, res) => {
  try {
    const {
      hotel,
      roomType = 'Deluxe Room',
      pricePerNight,
      numberOfRooms = 1,
      checkInDate,
      checkOutDate,
      guests = { adults: 1, children: 0 },
      contactDetails,
      specialRequests = '',
    } = req.body;

    if (!hotel || !pricePerNight || !checkInDate || !checkOutDate) {
      return res.status(400).json({
        message: 'Missing required booking parameters: hotel, pricePerNight, checkInDate, and checkOutDate are required.',
      });
    }

    const checkIn = new Date(checkInDate);
    const checkOut = new Date(checkOutDate);

    if (isNaN(checkIn.getTime()) || isNaN(checkOut.getTime())) {
      return res.status(400).json({ message: 'Invalid check-in or check-out date format.' });
    }

    if (checkOut <= checkIn) {
      return res.status(400).json({ message: 'Check-out date must be after check-in date.' });
    }

    const diffTime = Math.abs(checkOut.getTime() - checkIn.getTime());
    const numberOfNights = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));

    // Calculate transparent pricing
    const baseTotal = Number(pricePerNight) * Number(numberOfRooms) * numberOfNights;
    const taxAndFees = Math.round(baseTotal * 0.12); // 12% GST/Taxes
    const totalAmount = baseTotal + taxAndFees;

    const user = await User.findById(req.user.id);
    const fallbackContact = {
      name: user ? user.name : 'Valued Guest',
      email: user ? user.email : '',
      phone: '',
    };

    const finalContact = {
      name: contactDetails?.name?.trim() || fallbackContact.name,
      email: contactDetails?.email?.trim() || fallbackContact.email,
      phone: contactDetails?.phone?.trim() || fallbackContact.phone,
    };

    const booking = await Booking.create({
      user: req.user.id,
      bookingReference: generateBookingReference(),
      hotel: {
        id: hotel.id || '',
        title: hotel.title || 'Selected Hotel',
        category: 'Hotels',
        rating: hotel.rating || 4.5,
        location: hotel.city || hotel.address || '',
        image: hotel.image || 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
      },
      roomType,
      pricePerNight: Number(pricePerNight),
      numberOfRooms: Number(numberOfRooms),
      checkInDate: checkIn,
      checkOutDate: checkOut,
      numberOfNights,
      guests,
      contactDetails: finalContact,
      specialRequests: specialRequests.trim(),
      pricing: {
        baseTotal,
        taxAndFees,
        totalAmount,
      },
      status: 'confirmed',
    });

    // Update user stats
    if (user) {
      user.travelStats.tripsCount = (user.travelStats.tripsCount || 0) + 1;
      await user.save();
    }

    res.status(201).json({
      message: 'Hotel booking successfully confirmed!',
      booking,
    });
  } catch (error) {
    console.error(`Create Booking Error: ${error.message}`);
    res.status(500).json({ message: 'Failed to create booking.', error: error.message });
  }
};

/**
 * Retrieve all bookings for the authenticated user
 * ROUTE: GET /api/bookings/my-bookings
 * Requires authentication
 */
exports.getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ user: req.user.id }).sort({ createdAt: -1 });
    res.status(200).json(bookings);
  } catch (error) {
    console.error(`Get Bookings Error: ${error.message}`);
    res.status(500).json({ message: 'Server error retrieving your bookings.' });
  }
};

/**
 * Retrieve single booking by ID
 * ROUTE: GET /api/bookings/:id
 * Requires authentication
 */
exports.getBookingById = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      user: req.user.id,
    });

    if (!booking) {
      return res.status(404).json({ message: 'Booking not found.' });
    }

    res.status(200).json(booking);
  } catch (error) {
    console.error(`Get Booking Detail Error: ${error.message}`);
    res.status(500).json({ message: 'Server error retrieving booking detail.' });
  }
};

/**
 * Cancel an active booking
 * ROUTE: POST /api/bookings/:id/cancel
 * Requires authentication
 */
exports.cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      user: req.user.id,
    });

    if (!booking) {
      return res.status(404).json({ message: 'Booking not found.' });
    }

    if (booking.status === 'cancelled') {
      return res.status(400).json({ message: 'This booking is already cancelled.' });
    }

    booking.status = 'cancelled';
    await booking.save();

    res.status(200).json({
      message: 'Booking successfully cancelled.',
      booking,
    });
  } catch (error) {
    console.error(`Cancel Booking Error: ${error.message}`);
    res.status(500).json({ message: 'Server error while cancelling booking.' });
  }
};
