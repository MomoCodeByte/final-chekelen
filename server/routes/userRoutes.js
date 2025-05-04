const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { auth } = require('../middleware/auth'); // 

router.post('/', userController.createUser);
router.post('/login', userController.loginUser);
router.post('/logout', auth, userController.logout); // 
router.get('/', auth, userController.getUsers);
router.get('/role/:role', auth, userController.getUserRoles); // Fixed route for getting users by role
router.get('/:id', auth, userController.getUserById);
router.put('/:id', auth, userController.updateUser);
router.delete('/:id', auth, userController.deleteUser);

module.exports = router;
