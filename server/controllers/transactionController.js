const db = require('../Config/db');

// Define valid transaction types and statuses
const validTransactionTypes = ['purchase', 'refund', 'commission'];
const validStatuses = ['pending', 'completed', 'failed'];

// Create transaction
exports.createTransaction = (req, res) => {
    const { user_id, amount, transaction_type, status } = req.body;

    // Validate transaction type and status
    if (!validTransactionTypes.includes(transaction_type)) {
        return res.status(400).json({ message: 'Invalid transaction type.' });
    }
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status.' });
    }

    db.query('INSERT INTO transactions (user_id, amount, transaction_type, status) VALUES (?, ?, ?, ?)', 
             [user_id, amount, transaction_type, status], 
             (err, results) => {
                 if (err) {
                     console.error(err);
                     return res.status(500).json({ message: 'Error creating transaction.' });
                 }
                 res.status(201).json({ id: results.insertId });
             });
};

// Get all transactions
exports.getTransactions = (req, res) => {
    db.query('SELECT * FROM transactions', (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error fetching transactions.' });
        }
        res.json(results);
    });
};

// Get transaction by ID
exports.getTransactionById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM transactions WHERE transaction_id = ?', [id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error fetching transaction.' });
        }
        if (results.length === 0) {
            return res.status(404).json({ message: 'Transaction not found.' });
        }
        res.json(results[0]);
    });
};

// Update transaction
exports.updateTransaction = (req, res) => {
    const { id } = req.params;
    const { user_id, amount, transaction_type, status } = req.body;

    // Validate transaction type and status
    if (transaction_type && !validTransactionTypes.includes(transaction_type)) {
        return res.status(400).json({ message: 'Invalid transaction type.' });
    }
    if (status && !validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status.' });
    }

    db.query('UPDATE transactions SET user_id = ?, amount = ?, transaction_type = ?, status = ? WHERE transaction_id = ?', 
             [user_id, amount, transaction_type, status, id], 
             (err, results) => {
                 if (err) {
                     console.error(err);
                     return res.status(500).json({ message: 'Error updating transaction.' });
                 }
                 res.json({ message: 'Transaction updated successfully.' });
             });
};

// Update transaction status
exports.updateTransactionStatus = (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    // Validate status
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status.' });
    }

    db.query('UPDATE transactions SET status = ? WHERE transaction_id = ?', 
             [status, id], 
             (err, results) => {
                 if (err) {
                     console.error(err);
                     return res.status(500).json({ message: 'Error updating transaction status.' });
                 }
                 res.json({ message: 'Transaction status updated successfully.' });
             });
};

// Delete transaction
exports.deleteTransaction = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM transactions WHERE transaction_id = ?', [id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error deleting transaction.' });
        }
        res.json({ message: 'Transaction deleted successfully.' });
    });
};