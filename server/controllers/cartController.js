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

// ─── CART MANAGEMENT ────────────────────────────────────────────────────

/**
 * Adds or increments a crop in the cart.
 * Allows customers and farmers to manage carts.
 * Validates crop availability and input data.
 * Uses ON DUPLICATE KEY UPDATE to increment quantity if item exists.
 */
exports.addToCart = async (req, res) => {
  if (req.user.role !== 'customer' && req.user.role !== 'farmer') {
    return res.status(403).json({ message: 'Only customers and farmers can add to cart' });
  }
  const userId = req.user.id;
  const { crop_id, quantity } = req.body;

  if (!crop_id || !quantity || quantity <= 0) {
    return res.status(400).json({ message: 'Invalid crop_id or quantity' });
  }

  try {
    // Check if crop exists and is available
    const cropResult = await queryAsync(
      'SELECT is_available, name, price FROM crops WHERE crop_id = ?',
      [crop_id]
    );
    
    if (!cropResult.length || cropResult[0].is_available !== 1) {
      console.log(`Crop ID ${crop_id} (${cropResult[0]?.name || 'unknown'}) is not available`);
      return res.status(400).json({ message: 'Crop is not available' });
    }

    // Add to cart (or update existing item)
    await queryAsync(
      `INSERT INTO cart_items (user_id, crop_id, quantity)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)`,
      [userId, crop_id, quantity]
    );

    console.log(`User ${userId} (role: ${req.user.role}) added ${quantity} of crop ${crop_id} to cart`);
    
    // Return the updated cart
    const updatedCart = await getCartItems(userId);
    res.status(201).json({ 
      message: 'Added to cart',
      cart: updatedCart
    });
  } catch (err) {
    console.error('Error adding to cart:', err.message);
    res.status(500).json({ error: err.message });
  }
};

/**
 * Updates the quantity of a specific item in the cart.
 * Allows customers and farmers to modify item quantities.
 * Validates ownership and crop availability.
 */
exports.updateCartItem = async (req, res) => {
  if (req.user.role !== 'customer' && req.user.role !== 'farmer') {
    return res.status(403).json({ message: 'Only customers and farmers can modify cart' });
  }
  
  const userId = req.user.id;
  const cartItemId = req.params.id;
  const { quantity } = req.body;

  if (!quantity || quantity <= 0) {
    return res.status(400).json({ message: 'Invalid quantity' });
  }

  try {
    // Check if cart item exists and belongs to user
    const cartItem = await queryAsync(
      `SELECT ci.cart_item_id, ci.crop_id, c.is_available 
       FROM cart_items ci
       JOIN crops c ON ci.crop_id = c.crop_id
       WHERE ci.cart_item_id = ? AND ci.user_id = ?`,
      [cartItemId, userId]
    );

    if (!cartItem.length) {
      return res.status(404).json({ message: 'Cart item not found or not owned' });
    }

    if (cartItem[0].is_available !== 1) {
      return res.status(400).json({ message: 'Crop is no longer available' });
    }

    // Update quantity
    await queryAsync(
      `UPDATE cart_items SET quantity = ? WHERE cart_item_id = ?`,
      [quantity, cartItemId]
    );

    console.log(`User ${userId} (role: ${req.user.role}) updated cart item ${cartItemId} to quantity ${quantity}`);
    
    // Return updated cart
    const updatedCart = await getCartItems(userId);
    res.json({ 
      message: 'Cart item updated',
      cart: updatedCart
    });
  } catch (err) {
    console.error('Error updating cart item:', err.message);
    res.status(500).json({ error: err.message });
  }
};

/**
 * Retrieves the cart with crop details and line totals.
 * Allows customers and farmers to view their carts.
 * Joins cart_items with crops to include name, price, and availability.
 */
exports.getCart = async (req, res) => {
  if (req.user.role !== 'customer' && req.user.role !== 'farmer') {
    return res.status(403).json({ message: 'Only customers and farmers can view cart' });
  }
  const userId = req.user.id;

  try {
    const cartItems = await getCartItems(userId);
    
    // Calculate cart summary
    const cartSummary = {
      items: cartItems,
      item_count: cartItems.length,
      total_quantity: cartItems.reduce((sum, item) => sum + item.quantity, 0),
      subtotal: parseFloat(cartItems.reduce((sum, item) => sum + item.line_total, 0).toFixed(2))
    };

    res.json(cartSummary);
  } catch (err) {
    console.error('Error retrieving cart:', err.message);
    res.status(500).json({ error: err.message });
  }
};

/**
 * Removes a specific item from the cart.
 * Allows customers and farmers to modify their carts.
 * Validates ownership to prevent unauthorized deletion.
 */
exports.removeFromCart = async (req, res) => {
  if (req.user.role !== 'customer' && req.user.role !== 'farmer') {
    return res.status(403).json({ message: 'Only customers and farmers can modify cart' });
  }
  const userId = req.user.id;
  const cartItemId = req.params.id;

  try {
    const result = await queryAsync(
      `DELETE FROM cart_items 
       WHERE cart_item_id = ? AND user_id = ?`,
      [cartItemId, userId]
    );
    
    if (result.affectedRows === 0) {
      console.log(`Cart item ${cartItemId} not found for user ${userId} (role: ${req.user.role})`);
      return res.status(404).json({ message: 'Cart item not found or not owned' });
    }
    
    console.log(`User ${userId} (role: ${req.user.role}) removed cart item ${cartItemId}`);
    
    // Return updated cart
    const updatedCart = await getCartItems(userId);
    res.json({ 
      message: 'Removed from cart',
      cart: updatedCart
    });
  } catch (err) {
    console.error('Error removing from cart:', err.message);
    res.status(500).json({ error: err.message });
  }
};

/**
 * Clears all items from the user's cart.
 * Allows customers and farmers to empty their carts.
 */
exports.clearCart = async (req, res) => {
  if (req.user.role !== 'customer' && req.user.role !== 'farmer') {
    return res.status(403).json({ message: 'Only customers and farmers can modify cart' });
  }
  const userId = req.user.id;

  try {
    await queryAsync(
      `DELETE FROM cart_items WHERE user_id = ?`,
      [userId]
    );
    
    console.log(`User ${userId} (role: ${req.user.role}) cleared their cart`);
    res.json({ message: 'Cart cleared successfully' });
  } catch (err) {
    console.error('Error clearing cart:', err.message);
    res.status(500).json({ error: err.message });
  }
};

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
      // Get cart items with crop details
      const cartItems = await queryAsync(
        `SELECT c.crop_id, c.quantity, p.price, p.farmer_id, p.name
         FROM cart_items c
         JOIN crops p ON p.crop_id = c.crop_id
         WHERE c.user_id = ? AND p.is_available = 1`,
        [userId]
      );
      
      console.log('Cart items for checkout:', cartItems);
      cartItems.forEach(item => {
        console.log('Item:', item);
        console.log('Quantity type:', typeof item.quantity, 'Value:', item.quantity);
        console.log('Price type:', typeof item.price, 'Value:', item.price);
      });

      if (!cartItems.length) {
        console.log(`Checkout failed for user ${userId} (role: ${role}): Cart is empty or contains unavailable items`);
        throw new Error('Cart is empty or contains unavailable items');
      }

      // For farmers, validate they're only buying their own crops
      if (role === 'farmer') {
        const invalidItems = cartItems.filter(item => item.farmer_id !== userId);
        if (invalidItems.length > 0) {
          console.log(`Checkout failed for farmer ${userId}: Cart contains items from other farmers`);
          throw new Error('Cart contains items not owned by this farmer');
        }
      }

      // Calculate total price
      const total = cartItems
        .reduce((sum, i) => sum + Number(i.quantity) * Number(i.price), 0)
        .toFixed(2);

      // Create order
      const orderResult = await queryAsync(
        `INSERT INTO orders (customer_id, total_price, order_status) 
         VALUES (?, ?, ?)`,
        [userId, total, 'pending']
      );
      const orderId = orderResult.insertId;

      // Create order items
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

      // Clear the cart
      await queryAsync(
        `DELETE FROM cart_items WHERE user_id = ?`,
        [userId]
      );

      console.log(`User ${userId} (role: ${role}) placed order ${orderId} with total ${total}`);
      
      // Return order details with items
      const orderDetails = {
        order_id: orderId,
        total_price: parseFloat(total),
        status: 'pending',
        items: cartItems.map(item => {
          const quantity = Number(item.quantity);
          const price = Number(item.price);
          if (isNaN(quantity) || isNaN(price)) {
            throw new Error(`Invalid quantity (${item.quantity}) or price (${item.price}) for crop ${item.crop_id}`);
          }
          return {
            crop_id: item.crop_id,
            name: item.name,
            quantity: quantity,
            unit_price: price,
            line_total: parseFloat((quantity * price).toFixed(2))
          };
        })
      };
      
      return orderDetails;
    });

    res.status(201).json({
      message: 'Order created successfully',
      order: result
    });
  } catch (err) {
    console.error('Checkout error:', err.message);
    res.status(err.message.includes('Cart is empty') ? 400 : 500).json({
      error: err.message,
    });
  }
};

// ─── HELPER FUNCTIONS ────────────────────────────────────────────────────

/**
 * Helper function to get cart items with details
 * @param {number} userId - User ID
 * @returns {Promise<Array>} Cart items with details
 */
async function getCartItems(userId) {
  const rows = await queryAsync(
    `SELECT 
       c.cart_item_id,
       c.quantity,
       p.crop_id,
       p.name,
       p.price,
       (CAST(c.quantity AS DECIMAL) * CAST(p.price AS DECIMAL)) AS line_total,
       p.is_available,
       p.farmer_id,
       u.username AS farmer_name
     FROM cart_items c
     JOIN crops p ON p.crop_id = c.crop_id
     LEFT JOIN users u ON p.farmer_id = u.user_id
     WHERE c.user_id = ?
     ORDER BY c.added_at DESC`,
    [userId]
  );
  
  if (!rows.length) {
    console.log(`Cart for user ${userId} is empty`);
    return [];
  }
  
  return rows.map(item => {
    const lineTotal = Number(item.line_total);
    if (isNaN(lineTotal)) {
      console.error(`Invalid line_total for item ${item.cart_item_id}: ${item.line_total}`);
      return {
        ...item,
        line_total: 0
      };
    }
    return {
      ...item,
      line_total: parseFloat(lineTotal.toFixed(2))
    };
  });
}