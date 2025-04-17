const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');

router.post('/', transactionController.createTransaction);
router.get('/', transactionController.getTransactions);
router.get('/:id', transactionController.getTransactionById);
router.put('/:id', transactionController.updateTransaction);
router.put('/:id/status', transactionController.updateTransactionStatus); // New endpoint for updating status
router.delete('/:id', transactionController.deleteTransaction);

module.exports = router;