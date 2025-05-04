// const express = require('express');
// const router = express.Router();
// const chatController = require('../controllers/chatController');

// router.post('/', chatController.createChat);
// router.get('/', chatController.getChats);
// router.get('/:id', chatController.getChatById);
// router.delete('/:id', chatController.deleteChat);

// module.exports = router;

const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { auth } = require('../middleware/auth');

router.post('/', auth, chatController.createChat);
router.get('/', auth, chatController.getChats);
router.get('/:id', auth, chatController.getChatById);
router.delete('/:id', auth, chatController.deleteChat);

module.exports = router;
