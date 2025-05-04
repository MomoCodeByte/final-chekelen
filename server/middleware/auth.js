const jwt = require('jsonwebtoken');

/**
 * Authentication middleware
 * Verifies JWT token and attaches user data to request
 */
const auth = (req, res, next) => {
  try {
    // Get token from header (handles both formats)
    const authHeader = req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ') 
      ? authHeader.replace('Bearer ', '') 
      : authHeader;
    
    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Attach user info to request
    req.user = decoded; // e.g., { id, role }
    
    next();
  } catch (error) {
    console.error('Authentication error:', error.message);
    res.status(401).json({ message: 'Invalid token' });
  }
};

/**
 * Middleware to restrict access to admin or farmer roles
 */
const adminOrFarmer = (req, res, next) => {
  // Make sure auth middleware was used first
  if (!req.user) {
    return res.status(401).json({ message: 'Authentication required' });
  }
  
  // Check user role 
  if (req.user.role === 'admin' || req.user.role === 'farmer') {
    return next();
  }
  
  // Deny access for other roles
  return res.status(403).json({ message: 'Access denied: Admin or Farmer only' });
};

module.exports = { auth, adminOrFarmer };