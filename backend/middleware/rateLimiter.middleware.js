/**
 * Lightweight, zero-dependency in-memory rate limiting middleware.
 * Protects server and external API quotas (like Gemini & Google Maps) from abuse.
 */
const rateLimit = ({ windowMs = 60 * 1000, max = 60, message = 'Too many requests from this IP, please try again later.' }) => {
  const requests = new Map();

  // Periodically cleanup expired entries every 2 minutes
  setInterval(() => {
    const now = Date.now();
    for (const [ip, data] of requests.entries()) {
      if (now - data.startTime > windowMs) {
        requests.delete(ip);
      }
    }
  }, 2 * 60 * 1000).unref();

  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress || '127.0.0.1';
    const now = Date.now();

    const record = requests.get(ip);

    if (!record) {
      requests.set(ip, { count: 1, startTime: now });
      return next();
    }

    if (now - record.startTime > windowMs) {
      // Window expired, reset counter
      record.count = 1;
      record.startTime = now;
      return next();
    }

    record.count++;

    if (record.count > max) {
      const retryAfter = Math.ceil((windowMs - (now - record.startTime)) / 1000);
      res.setHeader('Retry-After', retryAfter);
      return res.status(429).json({
        status: 429,
        error: 'Too Many Requests',
        message,
        retryAfterSeconds: retryAfter,
      });
    }

    next();
  };
};

// General rate limiter: 100 requests per minute per IP
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: 'API rate limit exceeded. Please wait a minute before making more requests.',
});

// Stricter rate limiter for AI generation endpoints: 15 requests per minute
const aiGenerationLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 15,
  message: 'AI generation limit reached. Please wait a minute before generating more itineraries or chat messages.',
});

module.exports = {
  rateLimit,
  apiLimiter,
  aiGenerationLimiter,
};
