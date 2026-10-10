const Trip = require('../models/trip.model');
const User = require('../models/user.model');
const { getGeminiModel, generateContentWithRetry, isRateLimitError } = require('../config/gemini');

// Helper to generate unique 6-character trip invite code
const generateInviteCode = () => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

/**
 * Generate a new travel itinerary using Gemini, and save it to the DB.
 */
exports.generateItinerary = async (req, res) => {
  try {
    const { destination, daysCount, travelStyle } = req.body;

    if (!destination || !daysCount || !travelStyle) {
      return res.status(400).json({ message: 'Destination, daysCount, and travelStyle are required.' });
    }

    const userId = req.user._id;
    const model = getGeminiModel();

    const prompt = `You are a professional travel agent and itinerary planner.
Generate a detailed day-by-day travel itinerary for destination: "${destination}".
Trip Details:
- Duration: ${daysCount} Days
- Travel Style: ${travelStyle}

For each day, schedule specific time-blocked activities (e.g., '09:00 AM', '01:00 PM', '07:30 PM') and include accurate geographic coordinates (latitude and longitude) for the landmark or location.
Format the response STRICTLY as a raw JSON array of objects. Do not include markdown wraps (like \`\`\`json), explanations, comments, or extra text.

JSON Structure Schema:
[
  {
    "dayNumber": 1,
    "events": [
      {
        "time": "09:00 AM",
        "title": "Check-in & Rest",
        "description": "Check in to accommodation, unpack, and settle down after your journey.",
        "latitude": 48.8566,
        "longitude": 2.3522
      },
      {
        "time": "02:00 PM",
        "title": "Eiffel Tower & Champ de Mars",
        "description": "Take an afternoon walking tour around the iconic tower and scenic gardens.",
        "latitude": 48.8584,
        "longitude": 2.2945
      }
    ]
  }
]`;

    const result = await generateContentWithRetry(model, {
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: 'application/json',
      },
    });

    const response = await result.response;
    const rawText = response.text().trim();

    let jsonText = rawText;
    const jsonMatch = rawText.match(/\[\s*\{[\s\S]*\}\s*\]/);
    if (jsonMatch) {
      jsonText = jsonMatch[0];
    }

    let itinerarySchedule;
    try {
      itinerarySchedule = JSON.parse(jsonText);
    } catch (parseError) {
      console.error('Gemini JSON Parse Error:', rawText);
      return res.status(500).json({
        message: 'Failed to generate itinerary. The AI returned an invalid data format.',
        error: parseError.message,
      });
    }

    // Save trip to database with unique invite code
    const trip = new Trip({
      userId,
      title: `${destination} Exploration`,
      destination,
      daysCount: Number(daysCount),
      travelStyle,
      inviteCode: generateInviteCode(),
      collaborators: [],
      itinerarySchedule,
      dates: 'TBD (Planned)',
    });

    await trip.save();

    // Increment user tripsCount in travelStats
    await User.findByIdAndUpdate(userId, {
      $inc: { 'travelStats.tripsCount': 1 },
    });

    res.status(201).json(trip);
  } catch (error) {
    console.error('Generate Itinerary Error:', error);
    if (isRateLimitError(error)) {
      return res.status(429).json({
        message: 'The AI Itinerary Planner is currently experiencing high demand. Please try again in a few seconds.',
        error: error.message,
      });
    }
    res.status(500).json({ message: 'Internal server error during itinerary generation.', error: error.message });
  }
};

/**
 * Fetch all saved travel itineraries (owned + collaborated) for the authenticated user.
 */
exports.getTrips = async (req, res) => {
  try {
    const userId = req.user._id;
    const trips = await Trip.find({
      $or: [
        { userId: userId },
        { 'collaborators.userId': userId }
      ]
    }).sort({ createdAt: -1 });

    res.status(200).json(trips);
  } catch (error) {
    console.error('Fetch Trips Error:', error);
    res.status(500).json({ message: 'Internal server error while fetching trips.', error: error.message });
  }
};

/**
 * Join a shared trip using an invite code.
 */
exports.joinTripByCode = async (req, res) => {
  try {
    const { inviteCode } = req.body;
    const user = req.user;

    if (!inviteCode) {
      return res.status(400).json({ message: 'Invite code is required.' });
    }

    const trip = await Trip.findOne({ inviteCode: inviteCode.trim().toUpperCase() });
    if (!trip) {
      return res.status(404).json({ message: 'Invalid or expired trip invite code.' });
    }

    if (trip.userId.toString() === user._id.toString()) {
      return res.status(400).json({ message: 'You are the creator of this trip.' });
    }

    const alreadyJoined = trip.collaborators.some(c => c.userId?.toString() === user._id.toString());
    if (alreadyJoined) {
      return res.status(200).json(trip);
    }

    trip.collaborators.push({
      userId: user._id,
      name: user.name || 'Travel Companion',
      email: user.email,
    });

    await trip.save();
    res.status(200).json(trip);
  } catch (error) {
    console.error('Join Trip Error:', error);
    res.status(500).json({ message: 'Failed to join trip.', error: error.message });
  }
};

/**
 * Add a custom activity/event to a specific day in the itinerary.
 */
exports.addCustomEvent = async (req, res) => {
  try {
    const { tripId } = req.params;
    const { dayNumber, time, title, description } = req.body;
    const user = req.user;

    if (!time || !title) {
      return res.status(400).json({ message: 'Time and title are required.' });
    }

    const trip = await Trip.findOne({
      _id: tripId,
      $or: [{ userId: user._id }, { 'collaborators.userId': user._id }]
    });

    if (!trip) {
      return res.status(404).json({ message: 'Trip not found or unauthorized.' });
    }

    let day = trip.itinerarySchedule.find(d => d.dayNumber === Number(dayNumber));
    if (!day) {
      day = { dayNumber: Number(dayNumber), events: [] };
      trip.itinerarySchedule.push(day);
    }

    day.events.push({
      time,
      title,
      description: description || 'Custom collaborative activity',
      votes: [],
      addedBy: user.name || 'Traveler',
    });

    await trip.save();
    res.status(200).json(trip);
  } catch (error) {
    console.error('Add Custom Event Error:', error);
    res.status(500).json({ message: 'Failed to add activity.', error: error.message });
  }
};

/**
 * Toggle upvote on a specific itinerary activity.
 */
exports.toggleEventVote = async (req, res) => {
  try {
    const { tripId, eventId } = req.params;
    const userId = req.user._id;

    const trip = await Trip.findOne({
      _id: tripId,
      $or: [{ userId: userId }, { 'collaborators.userId': userId }]
    });

    if (!trip) {
      return res.status(404).json({ message: 'Trip not found or unauthorized.' });
    }

    let foundEvent = null;
    for (const day of trip.itinerarySchedule) {
      const ev = day.events.id(eventId);
      if (ev) {
        foundEvent = ev;
        break;
      }
    }

    if (!foundEvent) {
      return res.status(404).json({ message: 'Activity event not found.' });
    }

    const voteIdx = foundEvent.votes.findIndex(v => v.toString() === userId.toString());
    if (voteIdx > -1) {
      foundEvent.votes.splice(voteIdx, 1); // Unvote
    } else {
      foundEvent.votes.push(userId); // Upvote
    }

    await trip.save();
    res.status(200).json(trip);
  } catch (error) {
    console.error('Toggle Vote Error:', error);
    res.status(500).json({ message: 'Failed to toggle vote.', error: error.message });
  }
};

/**
 * Delete a saved travel itinerary.
 */
exports.deleteTrip = async (req, res) => {
  try {
    const userId = req.user._id;
    const tripId = req.params.id;

    const trip = await Trip.findOneAndDelete({ _id: tripId, userId });

    if (!trip) {
      return res.status(404).json({ message: 'Trip not found or unauthorized.' });
    }

    // Decrement user tripsCount in travelStats
    await User.findByIdAndUpdate(userId, {
      $inc: { 'travelStats.tripsCount': -1 },
    });

    res.status(200).json({ message: 'Trip successfully deleted.' });
  } catch (error) {
    console.error('Delete Trip Error:', error);
    res.status(500).json({ message: 'Internal server error while deleting trip.', error: error.message });
  }
};
