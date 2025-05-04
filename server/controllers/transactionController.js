const db = require('../Config/db');

// Define valid transaction types and statuses
const validTransactionTypes = ['purchase', 'refund', 'commission'];
const validStatuses = ['pending', 'completed', 'failed'];

// =========================
// Create Transaction
// =========================
exports.createTransaction = (req, res) => {
    const { amount, transaction_type, status } = req.body;
    const user_id = req.user.id; // From JWT token

    if (!validTransactionTypes.includes(transaction_type)) {
        return res.status(400).json({ message: 'Invalid transaction type.' });
    }
    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status.' });
    }

    db.query(
        'INSERT INTO transactions (user_id, amount, transaction_type, status) VALUES (?, ?, ?, ?)',
        [user_id, amount, transaction_type, status],
        (err, results) => {
            if (err) {
                console.error(err);
                return res.status(500).json({ message: 'Error creating transaction.' });
            }
            res.status(201).json({ id: results.insertId });
        }
    );
};

// =========================
// Get All Transactions (with isolation)
// =========================
exports.getTransactions = (req, res) => {
    const { role, id } = req.user;

    let sql = 'SELECT * FROM transactions';
    const params = [];

    if (role !== 'admin') {
        sql += ' WHERE user_id = ?';
        params.push(id);
    }

    db.query(sql, params, (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error fetching transactions.' });
        }
        res.json(results);
    });
};

// =========================
// Get Transaction by ID (with isolation)
// =========================
exports.getTransactionById = (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    const role = req.user.role;

    let sql = 'SELECT * FROM transactions WHERE transaction_id = ?';
    let params = [id];

    if (role !== 'admin') {
        sql += ' AND user_id = ?';
        params.push(userId);
    }

    db.query(sql, params, (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error fetching transaction.' });
        }
        if (results.length === 0) {
            return res.status(404).json({ message: 'Transaction not found or access denied.' });
        }
        res.json(results[0]);
    });
};

// =========================
// Update Transaction (with isolation)
// =========================
exports.updateTransaction = (req, res) => {
    const { id } = req.params;
    const { amount, transaction_type, status } = req.body;
    const userId = req.user.id;
    const role = req.user.role;

    if (transaction_type && !validTransactionTypes.includes(transaction_type)) {
        return res.status(400).json({ message: 'Invalid transaction type.' });
    }
    if (status && !validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status.' });
    }

    let checkSql = 'SELECT * FROM transactions WHERE transaction_id = ?';
    let checkParams = [id];

    if (role !== 'admin') {
        checkSql += ' AND user_id = ?';
        checkParams.push(userId);
    }

    db.query(checkSql, checkParams, (err, results) => {
        if (err) return res.status(500).json({ message: 'Database error', error: err.message });
        if (results.length === 0) return res.status(403).json({ message: 'Access denied or transaction not found.' });

        db.query(
            'UPDATE transactions SET amount = ?, transaction_type = ?, status = ? WHERE transaction_id = ?',
            [amount, transaction_type, status, id],
            (err) => {
                if (err) return res.status(500).json({ message: 'Error updating transaction.' });
                res.json({ message: 'Transaction updated successfully.' });
            }
        );
    });
};

// =========================
// Update Transaction Status (Admin only)
// =========================
exports.updateTransactionStatus = (req, res) => {
    const { id } = req.params;
    const { status } = req.body;
    const role = req.user.role;

    if (role !== 'admin') {
        return res.status(403).json({ message: 'Access denied: Only admins can update transaction status.' });
    }

    if (!validStatuses.includes(status)) {
        return res.status(400).json({ message: 'Invalid status.' });
    }

    db.query(
        'UPDATE transactions SET status = ? WHERE transaction_id = ?',
        [status, id],
        (err) => {
            if (err) return res.status(500).json({ message: 'Error updating status.' });
            res.json({ message: 'Status updated successfully.' });
        }
    );
};

// =========================
// Delete Transaction (with isolation)
// =========================
exports.deleteTransaction = (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    const role = req.user.role;

    let checkSql = 'SELECT * FROM transactions WHERE transaction_id = ?';
    let checkParams = [id];

    if (role !== 'admin') {
        checkSql += ' AND user_id = ?';
        checkParams.push(userId);
    }

    db.query(checkSql, checkParams, (err, results) => {
        if (err) return res.status(500).json({ message: 'Database error', error: err.message });
        if (results.length === 0) return res.status(403).json({ message: 'Access denied or transaction not found.' });

        db.query('DELETE FROM transactions WHERE transaction_id = ?', [id], (err) => {
            if (err) return res.status(500).json({ message: 'Error deleting transaction.' });
            res.json({ message: 'Transaction deleted successfully.' });
        });
    });
};
