const db = require('../Config/db');

// Create transaction
exports.createTransaction = (req, res) => {
    const { user_id, amount, transaction_type, status } = req.body;
    db.query('INSERT INTO transactions (user_id, amount, transaction_type, status) VALUES (?, ?, ?, ?)', 
             [user_id, amount, transaction_type, status], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.status(201).json({ id: results.insertId });
             });
};

// Get all transactions
exports.getTransactions = (req, res) => {
    db.query('SELECT * FROM transactions', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Get transaction by ID
exports.getTransactionById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM transactions WHERE transaction_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Update transaction
exports.updateTransaction = (req, res) => {
    const { id } = req.params;
    const { user_id, amount, transaction_type, status } = req.body;
    db.query('UPDATE transactions SET user_id = ?, amount = ?, transaction_type = ?, status = ? WHERE transaction_id = ?', 
             [user_id, amount, transaction_type, status, id], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.json({ message: 'Transaction updated successfully.' });
             });
};

// Delete transaction
exports.deleteTransaction = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM transactions WHERE transaction_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json({ message: 'Transaction deleted successfully.' });
    });
};