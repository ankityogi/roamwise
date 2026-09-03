const express = require('express');
const router = express.Router();
const bookmarkController = require('../controllers/bookmark.controller');
const { protect } = require('../middleware/auth.middleware');

// Protect all bookmark routes
router.use(protect);

// URL: POST /api/bookmarks (Save a place)
router.post('/', bookmarkController.addBookmark);

// URL: GET /api/bookmarks (Fetch user's bookmarked list)
router.get('/', bookmarkController.getBookmarks);

// URL: DELETE /api/bookmarks/:id (Remove a bookmark)
router.delete('/:id', bookmarkController.deleteBookmark);

module.exports = router;
