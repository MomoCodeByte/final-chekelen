const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth'); // Import the auth middleware

router.post('/', userController.createUser);
router.post('/login', userController.loginUser); // Add this line for login
router.post('/logout', auth, userController.logout); // Protect this route
router.get('/', auth, userController.getUsers); // Protect this route
router.get('/:id', auth, userController.getUserById); // Protect this route
router.put('/:id', auth, userController.updateUser); // Protect this route
router.delete('/:id', auth, userController.deleteUser); // Protect this route

module.exports = router;