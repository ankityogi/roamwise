const Trip = require('../models/trip.model');
const User = require('../models/user.model');
const { getGeminiModel, generateContentWithRetry, isRateLimitError } = require('../config/gemini');

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

For each day, schedule specific time-blocked activities (e.g., '09:00 AM', '01:00 PM', '07:30 PM').
Format the response STRICTLY as a raw JSON array of objects. Do not include markdown wraps (like \`\`\`json), explanations, comments, or extra text.

JSON Structure Schema:
[
  {
    "dayNumber": 1,
    "events": [
      {
        "time": "09:00 AM",
        "title": "Check-in & Rest",
        "description": "Check in to accommodation, unpack, and settle down after your journey."
      },
      {
        "time": "02:00 PM",
        "title": "Initial Exploration",
        "description": "Take a walking tour of the local area to get familiar with key landmarks."
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

    // Safe extraction in case Gemini wraps the response in markdown blocks
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

    // Save trip to database
    const trip = new Trip({
      userId,
      title: `${destination} Exploration`,
      destination,
      daysCount: Number(daysCount),
      travelStyle,
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
 * Fetch all saved travel itineraries for the authenticated user.
 */
exports.getTrips = async (req, res) => {
  try {
    const userId = req.user._id;
    const trips = await Trip.find({ userId }).sort({ createdAt: -1 });
    res.status(200).json(trips);
  } catch (error) {
    console.error('Fetch Trips Error:', error);
    res.status(500).json({ message: 'Internal server error while fetching trips.', error: error.message });
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
