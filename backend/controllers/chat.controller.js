const { getGeminiModel, sendMessageWithRetry, isRateLimitError } = require('../config/gemini');

/**
 * Handles travel assistant conversational message requests using Gemini.
 */
exports.chatResponse = async (req, res) => {
  try {
    const { message, targetLanguage, history } = req.body;

    if (!message) {
      return res.status(400).json({ message: 'Message is required.' });
    }

    // Format chat history correctly for the Google Gen AI SDK
    const formattedHistory = [];
    if (Array.isArray(history)) {
      // Limit history to the last 10 messages to keep the token payload lightweight
      const recentHistory = history.slice(-10);
      for (const msg of recentHistory) {
        if (msg.text) {
          formattedHistory.push({
            role: msg.isMe ? 'user' : 'model',
            parts: [{ text: msg.text }],
          });
        }
      }
    }

    // Google Gen AI SDK requires the first message in history to have the 'user' role
    while (formattedHistory.length > 0 && formattedHistory[0].role !== 'user') {
      formattedHistory.shift();
    }

    // Determine custom prompt extensions based on active translation selections
    let languageDirective = "";
    if (targetLanguage === 'JA') {
      languageDirective = " Note: The user has active Japanese translation enabled. If they ask you to translate, translate it. Otherwise, respond friendly in English but introduce key Japanese words, travel phrases, or greetings (with romaji/pronunciation) to assist them in Japan.";
    } else if (targetLanguage === 'ES') {
      languageDirective = " Note: The user has active Spanish translation enabled. If they ask you to translate, translate it. Otherwise, respond friendly in English but introduce key Spanish phrases, local greetings, or travel terms to assist them in Spanish-speaking regions.";
    } else if (targetLanguage === 'FR') {
      languageDirective = " Note: The user has active French translation enabled. If they ask you to translate, translate it. Otherwise, respond friendly in English but introduce key French phrases, polite gestures, or local terms to assist them in French-speaking regions.";
    }

    const systemInstruction = 
      "You are the RoamWise Travel Assistant, an expert, friendly AI travel companion. " +
      "Help the traveler with plans, dining recommendations, sightseeing secrets, transit routes, and language translations. " +
      "Keep responses concise (usually 2-4 sentences or bullet points) and formatting clean." +
      languageDirective;

    const model = getGeminiModel(undefined, systemInstruction);

    const chatSession = model.startChat({
      history: formattedHistory,
    });

    const result = await sendMessageWithRetry(chatSession, message);
    const response = await result.response;
    const responseText = response.text().trim();

    res.status(200).json({ response: responseText });
  } catch (error) {
    console.error('Chat Assistant Error:', error);
    if (isRateLimitError(error)) {
      return res.status(429).json({
        message: 'The AI Travel Assistant is currently experiencing high demand. Please try again in a few seconds.',
        error: error.message,
      });
    }
    res.status(500).json({ message: 'Failed to generate travel assistant response.', error: error.message });
  }
};
