const db = require('../Config/db');

// Get user info from token (assumes middleware sets req.user)
const getUserInfo = (req) => ({
    id: req.user?.id,
    role: req.user?.role
});

// Report: Total users per role (Admins only)
exports.getUsersReport = (req, res) => {
    const { role } = getUserInfo(req);
    if (role !== 'admin') {
        return res.status(403).json({ message: 'Access denied' });
    }

    const query = `SELECT role, COUNT(*) AS total FROM users GROUP BY role`;
    db.query(query, (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Report: Total orders per status
exports.getOrdersReport = (req, res) => {
    const { role, id } = getUserInfo(req);
    let query = `SELECT order_status, COUNT(*) AS total FROM orders`;
    const params = [];

    if (role === 'customer') {
        query += ' WHERE customer_id = ?';
        params.push(id);
    } else if (role === 'farmer') {
        query = `
            SELECT o.order_status, COUNT(*) AS total
            FROM orders o
            JOIN crops c ON o.crop_id = c.crop_id
            WHERE c.farmer_id = ?
            GROUP BY o.order_status
        `;
        params.push(id);
    } else {
        query += ' GROUP BY order_status';
    }

    db.query(query, params, (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Report: Transactions per status (Admins see all, others only theirs)
exports.getTransactionsReport = (req, res) => {
    const { role, id } = getUserInfo(req);
    let query = `
        SELECT 
            SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END) AS total_completed,
            SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS total_pending,
            SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END) AS total_failed
        FROM transactions
    `;
    const params = [];

    if (role !== 'admin') {
        query += ' WHERE user_id = ?';
        params.push(id);
    }

    db.query(query, params, (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Report: Get active crops (Admins and farmers only)
exports.getCropsReport = (req, res) => {
    const { role, id } = getUserInfo(req);
    let query = `SELECT COUNT(*) AS total_crops FROM crops WHERE is_available = 1`;
    const params = [];

    if (role === 'farmer') {
        query += ' AND farmer_id = ?';
        params.push(id);
    }

    db.query(query, params, (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Report: Daily new orders (today only)
exports.getDailyOrders = (req, res) => {
    const { role, id } = getUserInfo(req);
    let query = `SELECT COUNT(*) AS daily_orders FROM orders WHERE DATE(created_at) = CURDATE()`;
    const params = [];

    if (role === 'customer') {
        query += ' AND customer_id = ?';
        params.push(id);
    } else if (role === 'farmer') {
        query = `
            SELECT COUNT(*) AS daily_orders
            FROM orders o
            JOIN crops c ON o.crop_id = c.crop_id
            WHERE DATE(o.created_at) = CURDATE() AND c.farmer_id = ?
        `;
        params.push(id);
    }

    db.query(query, params, (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};
