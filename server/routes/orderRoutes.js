const express = require('express');
const { auth } = require('../middleware/auth');
const orderController = require('../controllers/orderController');
const router = express.Router();

/**
 * @route POST /api/orders
 * @desc Create a new order for a customer
 * @access Private (customer, farmer)
 */
router.post('/', auth, orderController.createOrderForCustomer);

/**
 * @route GET /api/orders
 * @desc Get all orders for the current user
 * @access Private (all users - filtered by role)
 */
router.get('/', auth, orderController.getOrders);

/**
 * @route PUT /api/orders/:id
 * @desc Update an existing order
 * @access Private (farmer only)
 */
router.put('/:id', auth, orderController.updateOrder);

/**
 * @route PUT /api/orders/:id/status
 * @desc Update an order's status
 * @access Private (admin, farmer)
 */
router.put('/:id/status', auth, orderController.updateOrderStatus);

/**
 * @route DELETE /api/orders/:id
 * @desc Delete an order
 * @access Private (customer - pending orders only, farmer - own crops)
 */
router.delete('/:id', auth, orderController.deleteOrder);

/**
 * @route POST /api/orders/checkout
 * @desc Convert cart to order
 * @access Private (customer, farmer)
 */
router.post('/checkout', auth, orderController.checkout);

module.exports = router;