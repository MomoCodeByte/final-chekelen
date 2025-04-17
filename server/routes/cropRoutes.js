const express = require('express');
const router = express.Router();
const cropController = require('../controllers/cropController');

// Routes
router.post('/', cropController.createCrop); // Multer is now handled in the controller
router.get('/', cropController.getCrops);
router.get('/:id', cropController.getCropById);
router.put('/:id', cropController.updateCrop); // Multer is now handled in the controller
router.delete('/:id', cropController.deleteCrop);

// Remove the separate upload route as it's now integrated
module.exports = router;