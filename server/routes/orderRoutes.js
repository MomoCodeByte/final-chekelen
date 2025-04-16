const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

router.post('/', orderController.createOrder);                  // Create order
router.get('/', orderController.getOrders);                     // Get all orders
router.get('/:id', orderController.getOrderById);               // Get order by ID
router.put('/:id', orderController.updateOrder);                // Update order
router.put('/:id/status', orderController.updateOrderStatus);   // Update order status
router.delete('/:id', orderController.deleteOrder);             // Delete order

module.exports = router;