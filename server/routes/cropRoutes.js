const express = require('express');
const router = express.Router();
const cropController = require('../controllers/cropController');

// Routes
const { auth } = require('../middleware/auth');

// router.get('/', cropController.getCrops);
router.get('/public', cropController.getPublicCrops);
router.post('/', auth, cropController.createCrop);
router.get('/', auth, cropController.getCrops);
router.get('/:id', auth, cropController.getCropById);
router.put('/:id', auth, cropController.updateCrop);
router.delete('/:id', auth, cropController.deleteCrop);


// Remove the separate upload route as it's now integrated
module.exports = router;