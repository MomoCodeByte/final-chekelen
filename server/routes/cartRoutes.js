const express = require('express');
const { auth } = require('../middleware/auth');
const cartCtrl = require('../controllers/cartController');
const router = express.Router();

/**
 * Cart Routes
 * @route /api/cart
 */

/**
 * @route   GET /api/cart
 * @desc    Get user's cart with items
 * @access  Private (Customer, Farmer)
 */
router.get('/', auth, cartCtrl.getCart);

/**
 * @route   POST /api/cart
 * @desc    Add item to cart
 * @access  Private (Customer, Farmer)
 */
router.post('/', auth, cartCtrl.addToCart);

/**
 * @route   PUT /api/cart/:id
 * @desc    Update cart item quantity
 * @access  Private (Customer, Farmer)
 */
router.put('/:id', auth, cartCtrl.updateCartItem);

/**
 * @route   DELETE /api/cart/:id
 * @desc    Remove item from cart
 * @access  Private (Customer, Farmer)
 */
router.delete('/:id', auth, cartCtrl.removeFromCart);

/**
 * @route   DELETE /api/cart
 * @desc    Clear entire cart
 * @access  Private (Customer, Farmer)
 */
router.delete('/', auth, cartCtrl.clearCart);

/**
 * @route   POST /api/cart/checkout
 * @desc    Checkout cart and create order
 * @access  Private (Customer, Farmer)
 */
router.post('/checkout', auth, cartCtrl.checkout);

module.exports = router;