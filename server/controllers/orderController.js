const db = require('../Config/db');

// ─── HELPER FUNCTIONS ────────────────────────────────────────────────────

/**
 * Executes a database query with promise-based error handling.
 * @param {string} sql - SQL query string.
 * @param {Array} params - Query parameters.
 * @returns {Promise} Resolves with query results, rejects with error.
 */
const queryAsync = (sql, params) => {
  return new Promise((resolve, reject) => {
    db.query(sql, params, (err, result) => {
      if (err) reject(err);
      else resolve(result);
    });
  });
};

/**
 * Executes a transaction with multiple queries, rolling back on error.
 * Uses raw SQL transaction commands since db.getConnection is unavailable.
 * @param {Function} callback - Function containing queries to execute.
 * @returns {Promise} Resolves with callback result, rejects with error.
 */
const transactionAsync = async (callback) => {
  try {
    await queryAsync('START TRANSACTION', []);
    const result = await callback();
    await queryAsync('COMMIT', []);
    return result;
  } catch (err) {
    await queryAsync('ROLLBACK', []);
    throw err;
  }
};

// ─── CHECKOUT & ORDER FLOWS ──────────────────────────────────────────────

/**
 * Checks out the cart, creating an order and order items.
 * Allows customers and farmers to checkout.
 * Clears the cart after successful order creation.
 * Uses a transaction to ensure data consistency.
 */
exports.checkout = async (req, res) => {
  if (req.user.role !== 'customer' && req.user.role !== 'farmer') {
    return res.status(403).json({ message: 'Only customers and farmers may checkout' });
  }
  const userId = req.user.id;
  const role = req.user.role;

  try {
    const result = await transactionAsync(async () => {
      const cartItems = await queryAsync(
        `SELECT c.crop_id, c.quantity, p.price, p.farmer_id
         FROM cart_items c
         JOIN crops p ON p.crop_id = c.crop_id
         WHERE c.user_id = ? AND p.is_available = 1`,
        [userId]
      );
      console.log('Cart items for checkout:', cartItems);

      if (!cartItems.length) {
        console.log(`Checkout failed for user ${userId} (role: ${role}): Cart is empty or contains unavailable items`);
        throw new Error('Cart is empty or contains unavailable items');
      }

      if (role === 'farmer') {
        const invalidItems = cartItems.filter(item => item.farmer_id !== userId);
        if (invalidItems.length > 0) {
          console.log(`Checkout failed for farmer ${userId}: Cart contains items from other farmers`);
          throw new Error('Cart contains items not owned by this farmer');
        }
      }

      const total = cartItems
        .reduce((sum, i) => sum + i.quantity * i.price, 0)
        .toFixed(2);

      const orderResult = await queryAsync(
        `INSERT INTO orders (customer_id, total_price, order_status) 
         VALUES (?, ?, ?)`,
        [userId, total, 'pending']
      );
      const orderId = orderResult.insertId;

      const orderItems = cartItems.map((i) => [
        orderId,
        i.crop_id,
        i.quantity,
        i.price,
      ]);
      await queryAsync(
        `INSERT INTO order_items (order_id, crop_id, quantity, unit_price)
         VALUES ?`,
        [orderItems]
      );

      await queryAsync(
        `DELETE FROM cart_items WHERE user_id = ?`,
        [userId]
      );

      console.log(`User ${userId} (role: ${role}) placed order ${orderId} with total ${total}`);
      return { orderId, total };
    });

    res.status(201).json({
      order_id: result.orderId,
      total_price: result.total,
    });
  } catch (err) {
    console.error('Checkout error:', err.message);
    res.status(err.message.includes('Cart is empty') ? 400 : 500).json({
      error: err.message,
    });
  }
};

/**
 * Allows customers to create orders for themselves and farmers to create orders for customers.
 * Validates customer existence, crop availability, and farmer ownership (if applicable).
 * Uses a transaction to create order and order items atomically.
 */
exports.createOrderForCustomer = async (req, res) => {
  const { role, id: userId } = req.user;
  const { customer_id, order_items } = req.body;

  if (role !== 'customer' && role !== 'farmer') {
    return res.status(403).json({ message: 'Only customers and farmers can create orders' });
  }

  if (!order_items || !Array.isArray(order_items) || order_items.length === 0) {
    return res.status(400).json({ message: 'Order items are required' });
  }
  for (const item of order_items) {
    if (!item.crop_id || !item.quantity || item.quantity <= 0 || !item.unit_price || item.unit_price <= 0) {
      return res.status(400).json({ message: 'Invalid order item data' });
    }
  }

  let targetCustomerId = role === 'customer' ? userId : customer_id;
  if (role === 'farmer' && customer_id === undefined) {
    targetCustomerId = null;
  } else if (role === 'farmer' && !customer_id) {
    return res.status(400).json({ message: 'Customer ID must be provided or explicitly set to null for farmers' });
  }

  try {
    const result = await transactionAsync(async () => {
      if (targetCustomerId !== null) {
        const customerResult = await queryAsync(
          'SELECT user_id FROM users WHERE user_id = ? AND role = ?',
          [targetCustomerId, 'customer']
        );
        if (!customerResult.length) {
          throw new Error('Customer not found');
        }
      }

      const cropIds = order_items.map((item) => item.crop_id);
      let cropsSql = `
        SELECT crop_id, price, is_available, farmer_id 
        FROM crops 
        WHERE crop_id IN (?) AND is_available = 1
      `;
      let cropsParams = [cropIds];

      if (role === 'farmer') {
        cropsSql += ' AND farmer_id = ?';
        cropsParams.push(userId);
      }

      const cropsResult = await queryAsync(cropsSql, cropsParams);
      if (cropsResult.length !== cropIds.length) {
        const availableCropIds = cropsResult.map(c => c.crop_id);
        const unavailableCrops = cropIds.filter(id => !availableCropIds.includes(id));
        const unavailableDetails = await queryAsync(
          `SELECT crop_id, is_available, farmer_id 
           FROM crops 
           WHERE crop_id IN (?)`,
          [unavailableCrops]
        );
        let errorMessage = role === 'farmer' ? 'Some crops are unavailable or not owned by this farmer: ' : 'Some crops are unavailable: ';
        unavailableCrops.forEach(cropId => {
          const cropDetail = unavailableDetails.find(c => c.crop_id === cropId);
          if (!cropDetail) {
            errorMessage += `Crop ID ${cropId} does not exist; `;
          } else if (cropDetail.is_available !== 1) {
            errorMessage += `Crop ID ${cropId} is not available; `;
          } else if (role === 'farmer' && cropDetail.farmer_id !== userId) {
            errorMessage += `Crop ID ${cropId} is not owned by farmer ${userId}; `;
          }
        });
        throw new Error(errorMessage.trim().endsWith(':') ? errorMessage + 'Unknown reason' : errorMessage);
      }

      const total = order_items
        .reduce((sum, item) => sum + item.quantity * item.unit_price, 0)
        .toFixed(2);

      const orderResult = await queryAsync(
        `INSERT INTO orders (customer_id, total_price, order_status) 
         VALUES (?, ?, ?)`,
        [targetCustomerId, total, 'pending']
      );
      const orderId = orderResult.insertId;

      const orderItemsData = order_items.map((item) => [
        orderId,
        item.crop_id,
        item.quantity,
        item.unit_price,
      ]);
      await queryAsync(
        `INSERT INTO order_items (order_id, crop_id, quantity, unit_price)
         VALUES ?`,
        [orderItemsData]
      );

      console.log(`User ${userId} (role: ${role}) created order ${orderId} for customer ${targetCustomerId || 'NULL'}`);
      return { orderId, total };
    });

    res.status(201).json({
      order_id: result.orderId,
      total_price: result.total,
      message: 'Order created successfully',
    });
  } catch (err) {
    console.error('Error creating order:', err.message);
    res.status(err.message.includes('Customer not found') || err.message.includes('crops') ? 400 : 500).json({
      error: err.message,
    });
  }
};

/**
 * Updates an existing order's details (customer_id and order_items).
 * Only farmers can update orders for their crops.
 * Uses a transaction to update order and order items atomically.
 */
exports.updateOrder = async (req, res) => {
  if (req.user.role !== 'farmer') {
    return res.status(403).json({ message: 'Only farmers can update orders' });
  }
  const farmerId = req.user.id;
  const orderId = req.params.id;
  const { customer_id, order_items } = req.body;

  if (!order_items || !Array.isArray(order_items) || order_items.length === 0) {
    return res.status(400).json({ message: 'Order items are required' });
  }
  for (const item of order_items) {
    if (!item.crop_id || !item.quantity || item.quantity <= 0 || !item.unit_price || item.unit_price <= 0) {
      return res.status(400).json({ message: 'Invalid order item data' });
    }
  }

  let targetCustomerId = customer_id;
  if (customer_id === undefined) {
    targetCustomerId = null;
  }

  try {
    const result = await transactionAsync(async () => {
      const orderResult = await queryAsync(
        `SELECT o.order_id 
         FROM orders o 
         JOIN order_items oi ON o.order_id = oi.order_id 
         JOIN crops p ON oi.crop_id = p.crop_id 
         WHERE o.order_id = ? AND p.farmer_id = ?`,
        [orderId, farmerId]
      );
      if (!orderResult.length) {
        throw new Error('Order not found or not owned by this farmer');
      }

      if (targetCustomerId !== null) {
        const customerResult = await queryAsync(
          'SELECT user_id FROM users WHERE user_id = ? AND role = ?',
          [targetCustomerId, 'customer']
        );
        if (!customerResult.length) {
          throw new Error('Customer not found');
        }
      }

      const cropIds = order_items.map((item) => item.crop_id);
      const cropsResult = await queryAsync(
        `SELECT crop_id, price, is_available 
         FROM crops 
         WHERE crop_id IN (?) AND farmer_id = ? AND is_available = 1`,
        [cropIds, farmerId]
      );
      if (cropsResult.length !== cropIds.length) {
        console.log(`Farmer ${farmerId} attempted to update order ${orderId} with unavailable crops: ${cropIds}`);
        throw new Error('Some crops are unavailable or not owned by this farmer');
      }

      const total = order_items
        .reduce((sum, item) => sum + item.quantity * item.unit_price, 0)
        .toFixed(2);

      await queryAsync(
        `UPDATE orders 
         SET customer_id = ?, total_price = ?, order_status = ? 
         WHERE order_id = ?`,
        [targetCustomerId, total, 'pending', orderId]
      );

      await queryAsync(
        `DELETE FROM order_items WHERE order_id = ?`,
        [orderId]
      );

      const orderItemsData = order_items.map((item) => [
        orderId,
        item.crop_id,
        item.quantity,
        item.unit_price,
      ]);
      await queryAsync(
        `INSERT INTO order_items (order_id, crop_id, quantity, unit_price)
         VALUES ?`,
        [orderItemsData]
      );

      console.log(`Farmer ${farmerId} updated order ${orderId}`);
      return { orderId, total };
    });

    res.json({
      order_id: result.orderId,
      total_price: result.total,
      message: 'Order updated successfully',
    });
  } catch (err) {
    console.error('Error updating order:', err.message);
    res.status(err.message.includes('not found') || err.message.includes('crops') ? 400 : 500).json({
      error: err.message,
    });
  }
};

/**
 * Lists orders with items, filtered by user role.
 * Groups orders by order_id to match frontend expectations.
 */
exports.getOrders = async (req, res) => {
  const { role, id: userId } = req.user;
  let sql = `
    SELECT 
      o.order_id,
      o.customer_id,
      o.total_price,
      o.order_status,
      o.created_at,
      oi.order_item_id,
      oi.crop_id,
      oi.quantity,
      oi.unit_price,
      p.name AS crop_name
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN crops p ON oi.crop_id = p.crop_id
  `;
  const params = [];

  if (role === 'customer') {
    sql += ' WHERE o.customer_id = ?';
    params.push(userId);
  } else if (role === 'farmer') {
    sql += ' WHERE p.farmer_id = ?';
    params.push(userId);
  }

  sql += ' ORDER BY o.created_at DESC, oi.order_item_id';

  try {
    const rows = await queryAsync(sql, params);
    const groupedOrders = {};
    rows.forEach((row) => {
      const orderId = row.order_id;
      if (!groupedOrders[orderId]) {
        groupedOrders[orderId] = {
          order_id: orderId,
          customer_id: row.customer_id,
          total_price: row.total_price,
          order_status: row.order_status,
          created_at: row.created_at,
          items: [],
        };
      }
      groupedOrders[orderId].items.push({
        order_item_id: row.order_item_id,
        crop_id: row.crop_id,
        quantity: row.quantity,
        unit_price: row.unit_price,
        crop_name: row.crop_name,
      });
    });

    console.log(`Fetched orders for user ${userId} (role: ${role})`);
    res.json(Object.values(groupedOrders));
  } catch (err) {
    console.error('Error fetching orders:', err.message);
    res.status(500).json({ error: err.message });
  }
};

/**
 * Updates an order's status (admin or farmer).
 * Farmers can only update orders for their crops.
 */
exports.updateOrderStatus = async (req, res) => {
  const { role, id: userId } = req.user;
  if (role !== 'admin' && role !== 'farmer') {
    return res.status(403).json({ message: 'Only admin or farmer can update status' });
  }

  const { id } = req.params;
  const { order_status } = req.body;
  const valid = ['pending', 'processed', 'shipped', 'delivered', 'cancelled'];
  if (!valid.includes(order_status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  try {
    let sql = 'UPDATE orders SET order_status = ? WHERE order_id = ?';
    const params = [order_status, id];

    if (role === 'farmer') {
      sql = `
        UPDATE orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN crops p ON oi.crop_id = p.crop_id
        SET o.order_status = ?
        WHERE o.order_id = ? AND p.farmer_id = ?
      `;
      params.push(userId);
    }

    const result = await queryAsync(sql, params);
    if (result.affectedRows === 0) {
      console.log(`Order ${id} not found or not owned by farmer ${userId}`);
      return res.status(403).json({ message: 'Order not found or not owned by this farmer' });
    }

    console.log(`Order ${id} status updated to ${order_status} by user ${userId} (role: ${role})`);
    res.json({ message: 'Order status updated' });
  } catch (err) {
    console.error('Error updating order status:', err.message);
    res.status(500).json({ error: err.message });
  }
};

/**
 * Deletes an order and its items.
 * Customers can only delete pending orders; farmers can delete orders for their crops.
 */
exports.deleteOrder = async (req, res) => {
  const { role, id: userId } = req.user;
  const orderId = req.params.id;

  try {
    if (role === 'customer') {
      const orderResult = await queryAsync(
        `SELECT order_status 
         FROM orders 
         WHERE order_id = ? AND customer_id = ?`,
        [orderId, userId]
      );
      if (!orderResult.length) {
        return res.status(403).json({ message: 'No such order to delete' });
      }
      if (orderResult[0].order_status !== 'pending') {
        return res.status(403).json({ message: 'Only pending orders can be deleted' });
      }
    } else if (role === 'farmer') {
      const orderResult = await queryAsync(
        `SELECT o.order_id 
         FROM orders o 
         JOIN order_items oi ON o.order_id = oi.order_id 
         JOIN crops p ON oi.crop_id = p.crop_id 
         WHERE o.order_id = ? AND p.farmer_id = ?`,
        [orderId, userId]
      );
      if (!orderResult.length) {
        return res.status(403).json({ message: 'No such order to delete' });
      }
    } else {
      return res.status(403).json({ message: 'Only customers or farmers can delete orders' });
    }

    await transactionAsync(async () => {
      await queryAsync(
        `DELETE FROM order_items WHERE order_id = ?`,
        [orderId]
      );
      await queryAsync(
        `DELETE FROM orders WHERE order_id = ?`,
        [orderId]
      );
    });

    console.log(`Order ${orderId} deleted by user ${userId} (role: ${role})`);
    res.json({ message: 'Order deleted' });
  } catch (err) {
    console.error('Error deleting order:', err.message);
    res.status(500).json({ error: err.message });
  }
};