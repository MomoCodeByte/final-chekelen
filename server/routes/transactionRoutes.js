const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');
const { auth } = require('../middleware/auth');

// Routes with auth middleware
router.post('/', auth, transactionController.createTransaction);
router.get('/', auth, transactionController.getTransactions);
router.get('/:id', auth, transactionController.getTransactionById);
router.put('/:id', auth, transactionController.updateTransaction);
router.put('/:id/status', auth, transactionController.updateTransactionStatus);
router.delete('/:id', auth, transactionController.deleteTransaction);

module.exports = router;
