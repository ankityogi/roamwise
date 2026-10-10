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

    const cleanEmail = email.toLowerCase().trim();

    // Check if the user already exists in the database
    const userExists = await User.findOne({ email: cleanEmail });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists with this email address.' });
    }

    // Hash the password securely before saving to DB
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create the User record in MongoDB
    const user = await User.create({
      name: name.trim(),
      email: cleanEmail,
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

    const cleanEmail = email.toLowerCase().trim();

    // Search for user by email address
    const user = await User.findOne({ email: cleanEmail });

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

/**
 * Update User Emergency Contacts list
 * ROUTE: PUT /api/auth/emergency-contacts
 * Requires JWT token verification middleware
 */
exports.updateEmergencyContacts = async (req, res) => {
  try {
    const { contacts } = req.body; // Expects an array: [{ name, phone }]

    if (!Array.isArray(contacts)) {
      return res.status(400).json({ message: 'Contacts payload must be an array.' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.emergencyContacts = contacts.map(c => ({
      name: c.name || '',
      phone: c.phone || '',
    }));

    await user.save();

    res.status(200).json({
      _id: user.id,
      name: user.name,
      email: user.email,
      profilePic: user.profilePic,
      travelStats: user.travelStats,
      emergencyContacts: user.emergencyContacts,
    });
  } catch (error) {
    console.error(`Update Emergency Contacts Error: ${error.message}`);
    res.status(500).json({ message: 'Server error updating emergency contacts.', error: error.message });
  }
};

/**
 * Authenticate or Register User using Google Account
 * ROUTE: POST /api/auth/google
 */
exports.googleAuth = async (req, res) => {
  try {
    const { idToken, email: clientEmail, name: clientName, photoUrl: clientPhoto, googleId: clientGoogleId } = req.body;

    if (!idToken && !clientEmail) {
      return res.status(400).json({ message: 'Google authentication payload is missing required tokens or profile data.' });
    }

    let verifiedEmail = clientEmail;
    let verifiedName = clientName;
    let verifiedPicture = clientPhoto;
    let verifiedGoogleId = clientGoogleId;

    // Verify ID Token with Google if provided
    if (idToken) {
      try {
        let OAuth2Client;
        try {
          OAuth2Client = require('google-auth-library').OAuth2Client;
        } catch (_) {
          // In case google-auth-library is not installed yet
        }

        if (OAuth2Client && process.env.GOOGLE_CLIENT_ID) {
          const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
          const ticket = await client.verifyIdToken({
            idToken,
            audience: process.env.GOOGLE_CLIENT_ID,
          });
          const payload = ticket.getPayload();
          verifiedEmail = payload.email;
          verifiedName = payload.name;
          verifiedPicture = payload.picture;
          verifiedGoogleId = payload.sub;
        } else if (typeof fetch === 'function') {
          // Built-in Node fetch fallback to Google tokeninfo endpoint
          const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`);
          if (response.ok) {
            const data = await response.json();
            verifiedEmail = data.email || verifiedEmail;
            verifiedName = data.name || verifiedName;
            verifiedPicture = data.picture || verifiedPicture;
            verifiedGoogleId = data.sub || verifiedGoogleId;
          }
        }
      } catch (verifyErr) {
        console.warn('Google token verification warning, falling back to client payload:', verifyErr.message);
      }
    }

    if (!verifiedEmail) {
      return res.status(400).json({ message: 'Could not extract valid email from Google sign-in.' });
    }

    const cleanEmail = verifiedEmail.toLowerCase().trim();

    // Check if user exists by googleId or email
    let user = await User.findOne({
      $or: [
        { googleId: verifiedGoogleId },
        { email: cleanEmail },
      ],
    });

    if (user) {
      // User exists - update googleId and picture if needed
      let changed = false;
      if (!user.googleId && verifiedGoogleId) {
        user.googleId = verifiedGoogleId;
        changed = true;
      }
      if (verifiedPicture && user.profilePic && user.profilePic.includes('unsplash')) {
        user.profilePic = verifiedPicture;
        changed = true;
      }
      if (changed) {
        await user.save();
      }
    } else {
      // Create new Google-authenticated user
      user = await User.create({
        name: verifiedName ? verifiedName.trim() : cleanEmail.split('@')[0],
        email: cleanEmail,
        googleId: verifiedGoogleId,
        authProvider: 'google',
        profilePic: verifiedPicture || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      });
    }

    res.status(200).json({
      _id: user.id,
      name: user.name,
      email: user.email,
      profilePic: user.profilePic,
      travelStats: user.travelStats,
      emergencyContacts: user.emergencyContacts,
      token: generateToken(user._id),
    });
  } catch (error) {
    console.error(`Google Auth Error: ${error.message}`);
    res.status(500).json({ message: 'Server error during Google sign-in.', error: error.message });
  }
};

