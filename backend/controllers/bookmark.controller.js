const Bookmark = require('../models/bookmark.model');
const User = require('../models/user.model');

/**
 * Add a new Place Bookmark for the user
 * ROUTE: POST /api/bookmarks
 */
exports.addBookmark = async (req, res) => {
  try {
    const { title, category, rating, price, distance, latitude, longitude } = req.body;

    if (!title || !category || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ message: 'Please provide all required fields: title, category, latitude, and longitude.' });
    }

    // Check if user already bookmarked this specific location to avoid duplicate bookmarks
    const existingBookmark = await Bookmark.findOne({
      userId: req.user.id,
      title,
      latitude,
      longitude,
    });

    if (existingBookmark) {
      return res.status(400).json({ message: 'This place is already bookmarked.' });
    }

    const bookmark = await Bookmark.create({
      userId: req.user.id,
      title,
      category,
      rating,
      price,
      distance,
      latitude,
      longitude,
    });

    // Update user statistics counter
    await User.findByIdAndUpdate(req.user.id, {
      $inc: { 'travelStats.savedItemsCount': 1 },
    });

    res.status(201).json(bookmark);
  } catch (error) {
    console.error(`Add Bookmark Error: ${error.message}`);
    res.status(500).json({ message: 'Server error saving bookmark.', error: error.message });
  }
};

/**
 * Get all Bookmarked places of the current user
 * ROUTE: GET /api/bookmarks
 */
exports.getBookmarks = async (req, res) => {
  try {
    const bookmarks = await Bookmark.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.status(200).json(bookmarks);
  } catch (error) {
    console.error(`Get Bookmarks Error: ${error.message}`);
    res.status(500).json({ message: 'Server error retrieving bookmarks.', error: error.message });
  }
};

/**
 * Delete a bookmarked place
 * ROUTE: DELETE /api/bookmarks/:id
 */
exports.deleteBookmark = async (req, res) => {
  try {
    const bookmark = await Bookmark.findById(req.params.id);

    if (!bookmark) {
      return res.status(404).json({ message: 'Bookmark not found.' });
    }

    // Ensure the bookmark belongs to the active logged-in user
    if (bookmark.userId.toString() !== req.user.id) {
      return res.status(401).json({ message: 'Not authorized to delete this bookmark.' });
    }

    await Bookmark.deleteOne({ _id: req.params.id });

    // Update user statistics counter
    await User.findByIdAndUpdate(req.user.id, {
      $inc: { 'travelStats.savedItemsCount': -1 },
    });

    res.status(200).json({ message: 'Bookmark removed successfully.' });
  } catch (error) {
    console.error(`Delete Bookmark Error: ${error.message}`);
    res.status(500).json({ message: 'Server error removing bookmark.', error: error.message });
  }
};
