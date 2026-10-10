const { getGeminiModel, generateContentWithRetry, isRateLimitError } = require('../config/gemini');

/**
 * Controller to analyze images for landmark identification or menu translation
 */
exports.analyzeImage = async (req, res) => {
  try {
    const { imageBase64, mimeType = 'image/jpeg', mode = 'landmark', targetLanguage = 'EN' } = req.body;

    if (!imageBase64) {
      return res.status(400).json({ message: 'imageBase64 data is required.' });
    }

    let prompt = '';
    if (mode === 'landmark') {
      prompt = `You are a world-class travel guide and architectural historian.
Analyze this image of a monument, landmark, or historical site.
Provide a clear, engaging travel breakdown strictly in clean JSON format.

JSON Schema:
{
  "name": "Exact Landmark Name",
  "city": "City, Country",
  "historicalSummary": "2-3 concise sentences detailing its history and importance.",
  "architecturalStyle": "Style (e.g. Gothic, Mughal, Modernist)",
  "visitingTips": [
    "Tip 1 (best time to visit)",
    "Tip 2 (entry or photography advice)"
  ],
  "funFact": "One fascinating trivia fact."
}`;
    } else if (mode === 'menu') {
      prompt = `You are an expert culinary travel guide and translator.
Analyze this photo of a foreign restaurant menu or food dish.
Translate all dishes into English (or requested language: ${targetLanguage}), describe ingredients, and note any potential dietary alerts (e.g. Vegetarian, Gluten, Spicy, Peanuts).
Provide the output strictly in clean JSON format.

JSON Schema:
{
  "menuTitle": "Cuisine or Restaurant Type",
  "dishes": [
    {
      "originalName": "Foreign Name on Menu",
      "translatedName": "English Translation",
      "description": "What it is, key ingredients, and taste profile",
      "dietaryAlert": "e.g. Vegetarian, Contains Peanuts, Mild, Spicy, Seafood",
      "estimatedPrice": "Price as seen on menu or TBD"
    }
  ],
  "recommendation": "The standout must-try dish on this menu."
}`;
    } else {
      prompt = `You are a travel assistant. Analyze this travel photo and describe its significance, location context, and travel advice in concise bullet points.`;
    }

    const model = getGeminiModel();

    const imagePart = {
      inlineData: {
        data: imageBase64.replace(/^data:image\/\w+;base64,/, ''),
        mimeType: mimeType,
      },
    };

    const result = await generateContentWithRetry(model, {
      contents: [
        {
          role: 'user',
          parts: [
            imagePart,
            { text: prompt + "\nRespond STRICTLY with valid raw JSON. Do not wrap in markdown or backticks." }
          ]
        }
      ],
      generationConfig: {
        responseMimeType: 'application/json',
      }
    });

    const response = await result.response;
    const rawText = response.text().trim();

    let jsonText = rawText;
    const jsonMatch = rawText.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      jsonText = jsonMatch[0];
    }

    let parsedResult;
    try {
      parsedResult = JSON.parse(jsonText);
    } catch (e) {
      console.warn('Vision JSON parse warning:', rawText);
      parsedResult = { rawSummary: rawText };
    }

    res.status(200).json({
      mode,
      result: parsedResult,
    });
  } catch (error) {
    console.error('Vision Analysis Error:', error);
    if (isRateLimitError(error)) {
      return res.status(429).json({
        message: 'The AI Vision Service is currently experiencing high demand. Please try again in a few seconds.',
        error: error.message,
      });
    }
    res.status(500).json({ message: 'Failed to analyze image with AI Vision.', error: error.message });
  }
};
