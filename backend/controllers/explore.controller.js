const { getGeminiModel, generateContentWithRetry, isRateLimitError } = require('../config/gemini');

/**
 * Dynamically generate local recommendations for a city and category using Gemini.
 */
exports.getExplorePlaces = async (req, res) => {
  try {
    const { city = 'Surat, India', category = 'All' } = req.query;

    const model = getGeminiModel();

    const prompt = `You are a local travel expert. 
Provide a list of 5 premium, highly-rated local places in "${city}" for the category: "${category}".
If category is "All", mix different categories.
Available categories: "Hotels", "Dining", "Sights", "Transit".

Format the response STRICTLY as a raw JSON array of objects. Do not include markdown wraps (like \`\`\`json), explanations, comments, or extra text.

JSON Structure Schema:
[
  {
    "title": "Name of the place",
    "category": "Hotels" | "Dining" | "Sights" | "Transit",
    "rating": 4.8,
    "price": "$$" | "$$$" | "$$$$" | "$",
    "distance": "0.5 km"
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

    let places;
    try {
      places = JSON.parse(jsonText);
    } catch (parseError) {
      console.error('Explore Places JSON Parse Error:', rawText);
      return res.status(500).json({
        message: 'Failed to parse explore recommendations.',
        error: parseError.message,
      });
    }

    res.status(200).json(places);
  } catch (error) {
    console.error('Explore Places Error:', error);
    if (isRateLimitError(error)) {
      return res.status(429).json({
        message: 'The AI recommendations service is currently experiencing high demand. Please try again in a few seconds.',
        error: error.message,
      });
    }
    res.status(500).json({ message: 'Internal server error while fetching explore places.', error: error.message });
  }
};
