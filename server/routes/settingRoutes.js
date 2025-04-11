const express = require('express');
const router = express.Router();
const settingController = require('../controllers/settingController');

router.post('/', settingController.createSetting);
router.get('/', settingController.getSettings);
router.get('/:id', settingController.getSettingById);
router.put('/:id', settingController.updateSetting);
router.delete('/:id', settingController.deleteSetting);

module.exports = router;