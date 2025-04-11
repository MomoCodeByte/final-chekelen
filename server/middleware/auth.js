const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET; // Use the secret from .env

const auth = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1]; // Get token from Authorization header
    if (!token) {
        return res.status(403).send('Token inaitajika uhakiki');
    }

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(401).send('Token si sahii');
        }
        req.user = decoded; // Save decoded token to request for use in other routes
        next();
    });
};

module.exports = auth;


// const jwt = require('jsonwebtoken');

// const JWT_SECRET = process.env.JWT_SECRET; // Use the secret from .env

// // Token blacklist storage - in production, use Redis or a database with TTL support
// const tokenBlacklist = new Set();

// /**
//  * Add a token to the blacklist
//  * @param {string} token - JWT token to blacklist
//  */
// const blacklistToken = (token) => {
//   if (token) {
//     tokenBlacklist.add(token);
//     console.log(`Token blacklisted: ${token}`);
//     // NOTE: In production, implement a cleanup mechanism or use Redis with TTL
//   }
// };

// /**
//  * Check if a token is blacklisted
//  * @param {string} token - JWT token to check
//  * @returns {boolean} - True if token is blacklisted
//  */
// const isTokenBlacklisted = (token) => {
//   return tokenBlacklist.has(token);
// };

// /**
//  * Authentication middleware
//  * Verifies JWT token and checks blacklist before allowing request
//  */
// const authenticate = (req, res, next) => {
//   try {
//     // Get token from Authorization header
//     const authHeader = req.headers.authorization;
//     const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer TOKEN"

//     if (!token) {
//       return res.status(401).json({ message: 'Authentication token missing' });
//     }

//     // Check if token is blacklisted (user has logged out)
//     if (isTokenBlacklisted(token)) {
//       return res.status(401).json({ message: 'Token revoked. Please login again.' });
//     }

//     // Verify the token
//     jwt.verify(token, JWT_SECRET, (err, decoded) => {
//       if (err) {
//         return res.status(401).json({ message: 'Invalid or expired token' });
//       }

//       // Attach user data to request object for use in subsequent handlers
//       req.user = decoded;
//       next();
//     });
//   } catch (error) {
//     console.error('Authentication error:', error);
//     return res.status(500).json({ message: 'Server error during authentication' });
//   }
// };

// module.exports = { auth: authenticate, blacklistToken, isTokenBlacklisted };