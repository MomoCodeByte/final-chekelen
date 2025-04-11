const db = require('../Config/db');

// Create order
exports.createOrder = (req, res) => {
    const { customer_id, crop_id, quantity, total_price } = req.body;
    db.query('INSERT INTO orders (customer_id, crop_id, quantity, total_price) VALUES (?, ?, ?, ?)', 
             [customer_id, crop_id, quantity, total_price], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.status(201).json({ id: results.insertId });
             });
};

// Get all orders
exports.getOrders = (req, res) => {
    db.query('SELECT * FROM orders', (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results);
    });
};

// Get order by ID
exports.getOrderById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM orders WHERE order_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json(results[0]);
    });
};

// Update order
exports.updateOrder = (req, res) => {
    const { id } = req.params;
    const { customer_id, crop_id, quantity, total_price, order_status } = req.body;
    db.query('UPDATE orders SET customer_id = ?, crop_id = ?, quantity = ?, total_price = ?, order_status = ? WHERE order_id = ?', 
             [customer_id, crop_id, quantity, total_price, order_status, id], 
             (err, results) => {
                 if (err) return res.status(500).send(err);
                 res.json({ message: 'Order updated successfully.' });
             });
};

// Delete order
exports.deleteOrder = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM orders WHERE order_id = ?', [id], (err, results) => {
        if (err) return res.status(500).send(err);
        res.json({ message: 'Order deleted successfully.' });
    });
};