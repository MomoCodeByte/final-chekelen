const db = require('../Config/db');

// Create order
exports.createOrder = (req, res) => {
    const { customer_id, crop_id, quantity, total_price } = req.body;
    const order_status = 'pending'; // Default status set to 'pending'
    
    db.query('INSERT INTO orders (customer_id, crop_id, quantity, total_price, order_status) VALUES (?, ?, ?, ?, ?)', 
             [customer_id, crop_id, quantity, total_price, order_status], 
             (err, results) => {
                 if (err) {
                     console.error(err);
                     return res.status(500).json({ message: 'Error creating order.' });
                 }
                 res.status(201).json({ id: results.insertId, order_status });
             });
};

// Get all orders
exports.getOrders = (req, res) => {
    db.query('SELECT * FROM orders', (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error fetching orders.' });
        }
        res.json(results);
    });
};

// Get order by ID
exports.getOrderById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM orders WHERE order_id = ?', [id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error fetching order.' });
        }
        if (results.length === 0) {
            return res.status(404).json({ message: 'Order not found.' });
        }
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
                 if (err) {
                     console.error(err);
                     return res.status(500).json({ message: 'Error updating order.' });
                 }
                 res.json({ message: 'Order updated successfully.' });
             });
};

// Update order status
exports.updateOrderStatus = (req, res) => {
    const { id } = req.params;
    const { order_status } = req.body; // Expecting just the status to update

    // Validate order_status value
    const validStatuses = ['pending', 'processed', 'shipped', 'delivered', 'canceled'];
    if (!validStatuses.includes(order_status)) {
        return res.status(400).json({ message: 'Invalid order status.' });
    }

    db.query('UPDATE orders SET order_status = ? WHERE order_id = ?', 
             [order_status, id], 
             (err, results) => {
                 if (err) {
                     console.error(err);
                     return res.status(500).json({ message: 'Error updating order status.' });
                 }
                 res.json({ message: 'Order status updated successfully.' });
             });
};

// Delete order
exports.deleteOrder = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM orders WHERE order_id = ?', [id], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).json({ message: 'Error deleting order.' });
        }
        res.json({ message: 'Order deleted successfully.' });
    });
};