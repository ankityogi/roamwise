const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

/**
 * Generate a JWT token containing the user's ID
 * @param {string} id - The MongoDB User object ID
 * @returns {string} - Signed JWT token valid for 30 days
 */
const generateToken = (id) => {
  const jwtSecret = process.env.JWT_SECRET || 'roamwise_secret_fallback_key';
  return jwt.sign({ id }, jwtSecret, {
    expiresIn: '30d',
  });
};

/**
 * Register a new User
 * ROUTE: POST /api/auth/register
 */
exports.registerUser = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validate inputs
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Please provide all required fields: name, email, and password.' });
    }

    // Check if the user already exists in the database
    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists with this email address.' });
    }

    // Hash the password securely before saving to DB
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create the User record in MongoDB
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
    });

    if (user) {
      res.status(201).json({
        _id: user.id,
        name: user.name,
        email: user.email,
        profilePic: user.profilePic,
        travelStats: user.travelStats,
        token: generateToken(user._id), // Send session token to client
      });
    } else {
      res.status(400).json({ message: 'Failed to create user. Invalid user data.' });
    }
  } catch (error) {
    console.error(`Register User Error: ${error.message}`);
    res.status(500).json({ message: 'Server error during registration.', error: error.message });
  }
};

/**
 * Authenticate/Log in an existing User
 * ROUTE: POST /api/auth/login
 */
exports.loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate inputs
    if (!email || !password) {
      return res.status(400).json({ message: 'Please provide both email and password.' });
    }

    // Search for user by email address
    const user = await User.findOne({ email });

    // Verify user exists and compare passwords
    if (user && (await bcrypt.compare(password, user.password))) {
      res.status(200).json({
        _id: user.id,
        name: user.name,
        email: user.email,
        profilePic: user.profilePic,
        travelStats: user.travelStats,
        token: generateToken(user._id), // Send session token to client
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password.' });
    }
  } catch (error) {
    console.error(`Login User Error: ${error.message}`);
    res.status(500).json({ message: 'Server error during login.', error: error.message });
  }
};

/**
 * Get authenticated User profile details
 * ROUTE: GET /api/auth/profile
 * Requires JWT token verification middleware
 */
exports.getUserProfile = async (req, res) => {
  try {
    // req.user is populated by the authentication middleware (authMiddleware)
    const user = await User.findById(req.user.id).select('-password'); // Exclude password hash from response

    if (user) {
      res.status(200).json(user);
    } else {
      res.status(404).json({ message: 'User not found.' });
    }
  } catch (error) {
    console.error(`Get Profile Error: ${error.message}`);
    res.status(500).json({ message: 'Server error retrieving user profile.' });
  }
};
