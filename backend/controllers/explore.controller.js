const { getGeminiModel, generateContentWithRetry, isRateLimitError } = require('../config/gemini');

// In-memory cache for explore search results (TTL: 1 hour)
const exploreCache = new Map();
const CACHE_TTL_MS = 60 * 60 * 1000;

// Curated default recommendations to serve as secondary offline fallback
const FALLBACK_PLACES = {
  Hotels: [
    { title: "Grand Heritage Resort", category: "Hotels", rating: 4.8, price: "3500", distance: "1.2 km", latitude: 21.1702, longitude: 72.8311 },
    { title: "Skyline Luxury Suites", category: "Hotels", rating: 4.7, price: "2800", distance: "2.5 km", latitude: 21.1750, longitude: 72.8250 },
  ],
  Dining: [
    { title: "Spice Bistro & Grill", category: "Dining", rating: 4.9, price: "600", distance: "0.8 km", latitude: 21.1680, longitude: 72.8350 },
    { title: "Urban Cafe & Patisserie", category: "Dining", rating: 4.6, price: "350", distance: "1.5 km", latitude: 21.1720, longitude: 72.8390 },
  ],
  Sights: [
    { title: "Historic City Fort", category: "Sights", rating: 4.8, price: "50", distance: "3.0 km", latitude: 21.1650, longitude: 72.8200 },
    { title: "Riverfront Promenade", category: "Sights", rating: 4.7, price: "0", distance: "1.1 km", latitude: 21.1800, longitude: 72.8280 },
  ],
  Transit: [
    { title: "Central Metro Station", category: "Transit", rating: 4.5, price: "30", distance: "0.5 km", latitude: 21.1710, longitude: 72.8320 },
    { title: "Express Bus Terminal", category: "Transit", rating: 4.4, price: "20", distance: "1.8 km", latitude: 21.1690, longitude: 72.8270 },
  ]
};

/**
 * Fetch real places using Google Places API (New)
 */
async function fetchGooglePlaces(city, category) {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  if (!apiKey) return null;

  let textQuery = `popular places and sights in ${city}`;
  if (category === 'Hotels') {
    textQuery = `top hotels and resorts in ${city}`;
  } else if (category === 'Dining') {
    textQuery = `top restaurants and cafes in ${city}`;
  } else if (category === 'Transit') {
    textQuery = `transit stations airport and transport in ${city}`;
  } else if (category === 'Sights') {
    textQuery = `famous tourist attractions and sights in ${city}`;
  }

  const url = 'https://places.googleapis.com/v1/places:searchText';
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.rating,places.priceLevel,places.primaryType'
    },
    body: JSON.stringify({
      textQuery,
      maxResultCount: 8
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.warn(`Places API (New) response error [${response.status}]: ${errorText}`);
    return null;
  }

  const data = await response.json();
  if (!data.places || data.places.length === 0) {
    return null;
  }

  return data.places.map((place) => {
    let priceDisplay = '2500';
    if (category === 'Dining') priceDisplay = '450';
    else if (category === 'Transit') priceDisplay = '50';
    else if (category === 'Sights') priceDisplay = '100';

    let resolvedCategory = category;
    if (category === 'All') {
      const type = (place.primaryType || '').toLowerCase();
      if (type.includes('restaurant') || type.includes('food') || type.includes('cafe')) {
        resolvedCategory = 'Dining';
      } else if (type.includes('hotel') || type.includes('lodging')) {
        resolvedCategory = 'Hotels';
      } else if (type.includes('transit') || type.includes('station') || type.includes('airport')) {
        resolvedCategory = 'Transit';
      } else {
        resolvedCategory = 'Sights';
      }
    }

    return {
      title: place.displayName?.text || 'Point of Interest',
      category: resolvedCategory,
      rating: place.rating || 4.6,
      price: priceDisplay,
      distance: place.formattedAddress ? place.formattedAddress.split(',')[0] : 'Nearby',
      latitude: place.location?.latitude || null,
      longitude: place.location?.longitude || null,
    };
  });
}

/**
 * Dynamically generate local recommendations for a city and category.
 * Prioritizes Google Places API (New) for verified real location coordinates and places.
 */
exports.getExplorePlaces = async (req, res) => {
  const { city = 'Surat, India', category = 'All' } = req.query;
  const cacheKey = `${city.toLowerCase().trim()}_${category.toLowerCase().trim()}`;

  // 1. Check in-memory cache first
  const cached = exploreCache.get(cacheKey);
  if (cached && (Date.now() - cached.timestamp < CACHE_TTL_MS)) {
    return res.status(200).json(cached.data);
  }

  // 2. Fetch from Google Places API (New) for real location data
  try {
    const googlePlaces = await fetchGooglePlaces(city, category);
    if (googlePlaces && googlePlaces.length > 0) {
      exploreCache.set(cacheKey, { data: googlePlaces, timestamp: Date.now() });
      return res.status(200).json(googlePlaces);
    }
  } catch (placesError) {
    console.warn('Google Places API query failed, falling back to Gemini/Curated:', placesError.message);
  }

  // 3. Fallback to Gemini AI Generation if Google Places was not available
  try {
    const model = getGeminiModel();

    const prompt = `You are a local travel expert. 
Provide a list of 5 premium, highly-rated real local places in "${city}" for the category: "${category}".
If category is "All", mix different categories.
Available categories: "Hotels", "Dining", "Sights", "Transit".

Format the response STRICTLY as a raw JSON array of objects. Do not include markdown wraps (like \`\`\`json), explanations, comments, or extra text.

JSON Structure Schema:
[
  {
    "title": "Name of the place",
    "category": "Hotels" | "Dining" | "Sights" | "Transit",
    "rating": 4.8,
    "price": "1500" | "300" | "2000" | "100",
    "distance": "0.5 km",
    "latitude": 21.1702,
    "longitude": 72.8311
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

    let places = JSON.parse(jsonText);
    exploreCache.set(cacheKey, { data: places, timestamp: Date.now() });
    return res.status(200).json(places);
  } catch (error) {
    console.error('Explore Places Error:', error.message);

    if (cached) {
      return res.status(200).json(cached.data);
    }

    const fallbackList = FALLBACK_PLACES[category] || Object.values(FALLBACK_PLACES).flat();
    return res.status(200).json(fallbackList);
  }
};

