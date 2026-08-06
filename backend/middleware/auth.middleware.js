const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

/**
 * Middleware function to authenticate JWT tokens sent in the Authorization headers
 */
const protect = async (req, res, next) => {
  let token;

  // Check if token exists in request headers and starts with 'Bearer'
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    try {
      // Extract token from Bearer prefix
      token = req.headers.authorization.split(' ')[1];

      // Decode and verify the token signature
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'roamwise_secret_fallback_key');

      // Fetch user details from MongoDB using ID encoded inside the token, exclude password
      req.user = await User.findById(decoded.id).select('-password');

      if (!req.user) {
        return res.status(401).json({ message: 'Not authorized. User does not exist.' });
      }

      // Proceed to the next middleware/controller handler
      return next();
    } catch (error) {
      console.error(`JWT Verification Middleware Error: ${error.message}`);
      return res.status(401).json({ message: 'Not authorized. Token verification failed.' });
    }
  }

  // Handle case where token is missing entirely
  if (!token) {
    return res.status(401).json({ message: 'Not authorized. No access token provided.' });
  }
};

module.exports = { protect };
