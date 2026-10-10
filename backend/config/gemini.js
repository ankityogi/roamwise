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
 * Utility to identify if an error is transient (rate limit 429, service unavailable 503, high demand).
 */
const isRateLimitError = (error) => {
  const msg = (error.message || "").toLowerCase();
  const status = error.status || error.statusCode;
  return (
    status === 429 ||
    status === 503 ||
    status === 500 ||
    msg.includes("429") ||
    msg.includes("503") ||
    msg.includes("resourceexhausted") ||
    msg.includes("rate limit") ||
    msg.includes("too many requests") ||
    msg.includes("high demand") ||
    msg.includes("service unavailable") ||
    msg.includes("temporarily unavailable")
  );
};

/**
 * Wraps content generation with automatic model failover and backoff.
 */
const generateContentWithRetry = async (model, params, maxRetries = 3, initialDelayMs = 1000) => {
  const fallbackModels = [
    process.env.GEMINI_MODEL || "gemini-flash-latest",
    "gemini-3.5-flash",
    "gemini-flash-latest",
    "gemini-3.1-flash-lite"
  ];

  for (const modelCandidate of fallbackModels) {
    let attempt = 0;
    while (attempt < maxRetries) {
      try {
        const activeModel = getGeminiModel(modelCandidate);
        return await activeModel.generateContent(params);
      } catch (error) {
        attempt++;
        if (isRateLimitError(error) && attempt < maxRetries) {
          const delay = initialDelayMs * Math.pow(1.5, attempt - 1);
          console.warn(`Transient error on ${modelCandidate}. Retrying in ${delay}ms...`);
          await new Promise((resolve) => setTimeout(resolve, delay));
        } else {
          console.warn(`Model ${modelCandidate} unavailable (${error.message?.slice(0, 80)}). Switching fallback model...`);
          break;
        }
      }
    }
  }
  throw new Error("All AI model endpoints are currently at peak capacity. Please try again shortly.");
};

/**
 * Wraps sending a chat message with fallback models and retry backoff.
 */
const sendMessageWithRetry = async (chatSession, message, maxRetries = 3, initialDelayMs = 1000) => {
  let attempt = 0;
  while (true) {
    try {
      return await chatSession.sendMessage(message);
    } catch (error) {
      attempt++;
      if (isRateLimitError(error) && attempt < maxRetries) {
        const delay = initialDelayMs * Math.pow(1.5, attempt - 1);
        console.warn(`Gemini API chat transient error (${error.status || 'overload'}). Retrying attempt ${attempt}/${maxRetries} in ${delay}ms...`);
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

