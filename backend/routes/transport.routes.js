const express = require('express');
const router = express.Router();
const transportController = require('../controllers/transport.controller');
const { protect } = require('../middleware/auth.middleware');

router.use(protect);

router.get('/', transportController.getTransports);
router.post('/', transportController.createTransport);
router.post('/:id/live-lookup', transportController.lookupLiveStatus);
router.delete('/:id', transportController.deleteTransport);

module.exports = router;
