const { GoogleGenerativeAI } = require("@google/generative-ai");

let genAI;

const initializeGenAI = () => {
  if (!genAI) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY is not defined. Please add it to your backend/.env file.");
    }
    genAI = new GoogleGenerativeAI(apiKey);
  }
  return genAI;
};

/**
 * Returns an instance of the configured generative model.
 * Uses process.env.GEMINI_MODEL or gemini-2.5-flash by default. Allows optional systemInstruction.
 */
const getGeminiModel = (modelName, systemInstruction) => {
  const client = initializeGenAI();
  const selectedModel = modelName || process.env.GEMINI_MODEL || "gemini-3.5-flash";
  const config = { model: selectedModel };
  if (systemInstruction) {
    config.systemInstruction = systemInstruction;
  }
  return client.getGenerativeModel(config);
};

/**
 * Utility to identify if an error is due to Gemini rate limits.
 */
const isRateLimitError = (error) => {
  return (
    error.status === 429 ||
    error.statusCode === 429 ||
    (error.message && (
      error.message.includes("429") ||
      error.message.toLowerCase().includes("resourceexhausted") ||
      error.message.toLowerCase().includes("rate limit") ||
      error.message.toLowerCase().includes("too many requests")
    ))
  );
};

/**
 * Wraps content generation with automatic exponential backoff.
 */
const generateContentWithRetry = async (model, params, maxRetries = 3, initialDelayMs = 1000) => {
  let attempt = 0;
  while (true) {
    try {
      return await model.generateContent(params);
    } catch (error) {
      attempt++;
      if (isRateLimitError(error) && attempt < maxRetries) {
        const delay = initialDelayMs * Math.pow(2, attempt - 1);
        console.warn(`Gemini API rate limited (429). Retrying attempt ${attempt}/${maxRetries} in ${delay}ms...`);
        await new Promise((resolve) => setTimeout(resolve, delay));
      } else {
        throw error;
      }
    }
  }
};

/**
 * Wraps sending a chat message with automatic exponential backoff.
 */
const sendMessageWithRetry = async (chatSession, message, maxRetries = 3, initialDelayMs = 1000) => {
  let attempt = 0;
  while (true) {
    try {
      return await chatSession.sendMessage(message);
    } catch (error) {
      attempt++;
      if (isRateLimitError(error) && attempt < maxRetries) {
        const delay = initialDelayMs * Math.pow(2, attempt - 1);
        console.warn(`Gemini API chat rate limited (429). Retrying attempt ${attempt}/${maxRetries} in ${delay}ms...`);
        await new Promise((resolve) => setTimeout(resolve, delay));
      } else {
        throw error;
      }
    }
  }
};

module.exports = {
  getGeminiModel,
  generateContentWithRetry,
  sendMessageWithRetry,
  isRateLimitError,
};

