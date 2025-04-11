const express = require('express');
const router = express.Router();
const cropController = require('../controllers/cropController');

router.post('/', cropController.createCrop);
router.get('/', cropController.getCrops);
router.get('/:id', cropController.getCropById);
router.put('/:id', cropController.updateCrop);
router.delete('/:id', cropController.deleteCrop);

module.exports = router;