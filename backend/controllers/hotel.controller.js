const { getGeminiModel, generateContentWithRetry } = require('../config/gemini');

// In-memory cache for hotel searches (TTL: 1 hour)
const hotelCache = new Map();
const CACHE_TTL_MS = 60 * 60 * 1000;

// Curated default luxury & boutique hotels fallback list
const FALLBACK_HOTELS = [
  {
    id: "htl-1",
    title: "Grand Heritage Palace & Spa",
    city: "Surat",
    address: "Dumas Road, Piplod, Surat, Gujarat 395007",
    rating: 4.8,
    reviewsCount: 342,
    pricePerNight: 4500,
    distance: "1.5 km from City Center",
    image: "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80",
    description: "Experience royal luxury with world-class hospitality, lush landscaped gardens, an outdoor infinity pool, and authentic gourmet dining.",
    amenities: ["Free High-Speed WiFi", "Infinity Pool", "Complimentary Breakfast", "Luxury Spa", "24/7 Room Service", "Airport Shuttle"],
    latitude: 21.1702,
    longitude: 72.8311,
    roomTypes: [
      {
        id: "rm-1",
        name: "Deluxe King Room",
        bed: "1 King Bed",
        maxGuests: 2,
        pricePerNight: 4500,
        features: ["City View", "Bathtub", "Balcony", "Free Breakfast"],
      },
      {
        id: "rm-2",
        name: "Executive Luxury Suite",
        bed: "1 King Bed + 1 Sofa Bed",
        maxGuests: 3,
        pricePerNight: 7200,
        features: ["Panoramic River View", "Jacuzzi", "Club Lounge Access", "Free Breakfast & Dinner"],
      },
    ],
  },
  {
    id: "htl-2",
    title: "The Urban Zenith Boutique Hotel",
    city: "Surat",
    address: "Ring Road, Near Majura Gate, Surat, Gujarat 395002",
    rating: 4.6,
    reviewsCount: 218,
    pricePerNight: 2800,
    distance: "0.8 km from City Center",
    image: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=80",
    description: "Contemporary urban oasis offering ultra-modern smart rooms, rooftop cafe lounge, and seamless proximity to shopping districts.",
    amenities: ["Free High-Speed WiFi", "Rooftop Restaurant", "Fitness Studio", "Valet Parking", "Smart TV & Workdesk"],
    latitude: 21.1850,
    longitude: 72.8200,
    roomTypes: [
      {
        id: "rm-3",
        name: "Superior Double Room",
        bed: "1 Queen Bed",
        maxGuests: 2,
        pricePerNight: 2800,
        features: ["Smart Room Automation", "Rain Shower", "Workdesk"],
      },
      {
        id: "rm-4",
        name: "Penthouse Studio",
        bed: "1 King Bed",
        maxGuests: 2,
        pricePerNight: 4900,
        features: ["Skyline Terrace", "Espresso Machine", "Complimentary Minibar"],
      },
    ],
  },
  {
    id: "htl-3",
    title: "Serene Riverside Courtyard",
    city: "Surat",
    address: "Tapi Riverfront Walk, Adajan, Surat, Gujarat 395009",
    rating: 4.7,
    reviewsCount: 189,
    pricePerNight: 3600,
    distance: "2.1 km from City Center",
    image: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=800&q=80",
    description: "A tranquil sanctuary overlooking the serene river, featuring sunlit courtyards, herbal spa treatments, and organic farm-to-table dining.",
    amenities: ["River View", "Organic Dining", "Yoga Deck", "Free High-Speed WiFi", "Concierge Tours"],
    latitude: 21.1920,
    longitude: 72.8110,
    roomTypes: [
      {
        id: "rm-5",
        name: "Courtyard Garden View",
        bed: "2 Twin Beds or 1 Queen",
        maxGuests: 2,
        pricePerNight: 3600,
        features: ["Private Patio", "Tea & Coffee Bar", "Botanical Toiletries"],
      },
    ],
  },
];

/**
 * Search and retrieve hotels for a given destination city with filters
 * ROUTE: GET /api/hotels
 */
exports.getHotels = async (req, res) => {
  const { city = 'Surat', minPrice, maxPrice, rating } = req.query;
  const cleanCity = city.trim();
  const cacheKey = `hotels_${cleanCity.toLowerCase()}`;

  // Check cache first
  const cached = hotelCache.get(cacheKey);
  if (cached && (Date.now() - cached.timestamp < CACHE_TTL_MS)) {
    let result = cached.data;
    if (minPrice) result = result.filter(h => h.pricePerNight >= Number(minPrice));
    if (maxPrice) result = result.filter(h => h.pricePerNight <= Number(maxPrice));
    if (rating) result = result.filter(h => h.rating >= Number(rating));
    return res.status(200).json(result);
  }

  try {
    const model = getGeminiModel();
    const prompt = `You are an expert travel accommodation recommender.
Provide 4 to 5 realistic, premium hotel options in "${cleanCity}".
Format the response STRICTLY as a raw JSON array of objects. Do not include markdown codeblocks (like \`\`\`json) or any conversational text.

JSON Schema:
[
  {
    "id": "htl-gemini-1",
    "title": "Hotel Name",
    "city": "${cleanCity}",
    "address": "Realistic local street address in ${cleanCity}",
    "rating": 4.7,
    "reviewsCount": 240,
    "pricePerNight": 3500,
    "distance": "1.2 km from City Center",
    "image": "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80",
    "description": "Short 2 sentence attractive description",
    "amenities": ["Free High-Speed WiFi", "Swimming Pool", "Complimentary Breakfast", "Fitness Center"],
    "latitude": 21.1702,
    "longitude": 72.8311,
    "roomTypes": [
      {
        "id": "rm-1",
        "name": "Deluxe Room",
        "bed": "1 King Bed",
        "maxGuests": 2,
        "pricePerNight": 3500,
        "features": ["Air Conditioned", "Balcony", "Free Breakfast"]
      },
      {
        "id": "rm-2",
        "name": "Executive Suite",
        "bed": "1 King Bed + 1 Sofa Bed",
        "maxGuests": 3,
        "pricePerNight": 5800,
        "features": ["Living Room", "Bathtub", "Panoramic View"]
      }
    ]
  }
]`;

    const result = await generateContentWithRetry(model, {
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: { responseMimeType: 'application/json' },
    });

    const response = await result.response;
    const rawText = response.text().trim();
    let jsonText = rawText;
    const jsonMatch = rawText.match(/\[\s*\{[\s\S]*\}\s*\]/);
    if (jsonMatch) jsonText = jsonMatch[0];

    let hotels;
    try {
      hotels = JSON.parse(jsonText);
    } catch (_) {
      hotels = FALLBACK_HOTELS;
    }

    // Cache the successful result
    hotelCache.set(cacheKey, { data: hotels, timestamp: Date.now() });

    let filtered = hotels;
    if (minPrice) filtered = filtered.filter(h => h.pricePerNight >= Number(minPrice));
    if (maxPrice) filtered = filtered.filter(h => h.pricePerNight <= Number(maxPrice));
    if (rating) filtered = filtered.filter(h => h.rating >= Number(rating));

    res.status(200).json(filtered);
  } catch (error) {
    console.warn('Hotel recommendation using fallback due to:', error.message);
    const fallbackWithCity = FALLBACK_HOTELS.map(h => ({
      ...h,
      city: cleanCity,
      address: h.address.replace('Surat', cleanCity),
    }));
    res.status(200).json(fallbackWithCity);
  }
};

/**
 * Get single hotel details by ID
 * ROUTE: GET /api/hotels/:id
 */
exports.getHotelById = async (req, res) => {
  const { id } = req.params;

  // Search across cached hotels or fallback list
  let foundHotel = null;
  for (const cacheItem of hotelCache.values()) {
    foundHotel = cacheItem.data.find(h => h.id === id);
    if (foundHotel) break;
  }

  if (!foundHotel) {
    foundHotel = FALLBACK_HOTELS.find(h => h.id === id) || FALLBACK_HOTELS[0];
  }

  res.status(200).json(foundHotel);
};
