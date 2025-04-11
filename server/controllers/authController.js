// const bcrypt = require("bcryptjs");
// const jwt = require("jsonwebtoken");
// require("dotenv").config();
// const {
//   createUser,
//   checkEmailExists,
//   getUserByEmail,
//   comparePassword,
// } = require("../models/authModel"); // Updated to reflect the new model name

// // Helper function for sending error responses
// const sendErrorResponse = (res, status, message) => {
//   return res.status(status).json({ message });
// };

// // Helper function to generate JWT token
// const generateToken = (user) => {
//   return jwt.sign(
//     { userId: user.id, email: user.email },
//     "mySuperSecretKey123!", // Replace with your secret key
//     { expiresIn: "1h" }
//   );
// };

// // Register controller
// const register = (req, res) => {
//   const { username, phone, email, password } = req.body;

//   // Input validation
//   if (!username || !phone || !email || !password) {
//     return sendErrorResponse(res, 400, "Jaza kila sehemu tafadhali.");
//   }

//   // Check if the email already exists
//   checkEmailExists(email, (err, results) => {
//     if (err) {
//       console.error(err);
//       return sendErrorResponse(res, 500, "Tatizo la database");
//     }
//     if (results.length > 0) {
//       return sendErrorResponse(res, 400, "Barua pepe hii inatumika tayari.");
//     }

//     // Create the user with hashed password
//     createUser(username, phone, email, password, (err, results) => {
//       if (err) {
//         console.error(err);
//         return sendErrorResponse(res, 500, "Tatizo la database");
//       }
//       res.status(201).json({ message: "Usajili umefanikiwa!" });
//     });
//   });
// };

// // Login controller
// const login = (req, res) => {
//   const { email, password } = req.body;

//   // Input validation
//   if (!email || !password) {
//     return sendErrorResponse(res, 400, "Tafadhali jaza sehemu zote.");
//   }

//   // Check if email exists
//   getUserByEmail(email, (err, results) => {
//     if (err) {
//       console.error(err);
//       return sendErrorResponse(res, 500, "Tatizo la database");
//     }
//     if (results.length === 0) {
//       return sendErrorResponse(res, 400, "Barua pepe hii haipo");
//     }

//     // Compare password
//     const user = results[0];
//     comparePassword(password, user.password, (err, isMatch) => {
//       if (err) {
//         console.error(err);
//         return sendErrorResponse(res, 500, "Tatizo la server");
//       }
//       if (!isMatch) {
//         return sendErrorResponse(res, 400, "Password sio sahihi");
//       }

//       // Generate and send JWT token
//       const token = generateToken(user);
//       res.status(200).json({ success: true, token });
//     });
//   });
// };

// module.exports = { register, login };
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
require("dotenv").config();
const {
  createUser,
  checkEmailExists,
  getUserByEmail,
  comparePassword,
} = require("../models/authModel");

// Token blacklist - in production use Redis or a database
const tokenBlacklist = new Set();

// Helper function for sending error responses
const sendErrorResponse = (res, status, message) => {
  return res.status(status).json({ message });
};

// Helper function to generate JWT token
const generateToken = (user) => {
  // Use environment variable for JWT secret instead of hardcoded value
  const JWT_SECRET = process.env.JWT_SECRET; // Fallback for development
  
  return jwt.sign(
    { userId: user.id, email: user.email },
    JWT_SECRET,
    { expiresIn: "1h" }
  );
};

// Register controller
const register = (req, res) => {
  const { username, phone, email, password } = req.body;
  
  // Input validation
  if (!username || !phone || !email || !password) {
    return sendErrorResponse(res, 400, "Jaza kila sehemu tafadhali.");
  }
  
  // Basic email format validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return sendErrorResponse(res, 400, "Barua pepe sio sahihi.");
  }
  
  // Password strength validation (at least 8 characters)
  if (password.length < 8) {
    return sendErrorResponse(res, 400, "Password inahitaji angalau herufi 8.");
  }

  // Check if the email already exists
  checkEmailExists(email, (err, results) => {
    if (err) {
      console.error("Database error during email check:", err);
      return sendErrorResponse(res, 500, "Tatizo la database");
    }
    
    if (results.length > 0) {
      return sendErrorResponse(res, 400, "Barua pepe hii inatumika tayari.");
    }
    
    // Create the user with hashed password
    createUser(username, phone, email, password, (err, results) => {
      if (err) {
        console.error("Database error during user creation:", err);
        return sendErrorResponse(res, 500, "Tatizo la database");
      }
      
      res.status(201).json({ 
        success: true,
        message: "Usajili umefanikiwa!" 
      });
    });
  });
};

// Login controller
const login = (req, res) => {
  const { email, password } = req.body;
  
  // Input validation
  if (!email || !password) {
    return sendErrorResponse(res, 400, "Tafadhali jaza sehemu zote.");
  }

  // Check if email exists
  getUserByEmail(email, (err, results) => {
    if (err) {
      console.error("Database error during login:", err);
      return sendErrorResponse(res, 500, "Tatizo la database");
    }
    
    if (results.length === 0) {
      return sendErrorResponse(res, 400, "Barua pepe hii haipo");
    }
    
    // Compare password
    const user = results[0];
    comparePassword(password, user.password, (err, isMatch) => {
      if (err) {
        console.error("Password comparison error:", err);
        return sendErrorResponse(res, 500, "Tatizo la server");
      }
      
      if (!isMatch) {
        return sendErrorResponse(res, 400, "Password sio sahihi");
      }
      
      // Generate and send JWT token
      const token = generateToken(user);
      
      // Return user info without sensitive data
      const safeUser = {
        id: user.id,
        username: user.username,
        email: user.email
      };
      
      res.status(200).json({ 
        success: true, 
        token,
        user: safeUser
      });
    });
  });
};

// Logout controller
const logout = (req, res) => {
  try {
    // Get token from authorization header
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer TOKEN"
    
    if (!token) {
      return sendErrorResponse(res, 400, "Hakuna token iliyotolewa");
    }
    
    // Add token to blacklist
    tokenBlacklist.add(token);
    
    // In production, you would want to store this in Redis with TTL
    // or a database with scheduled cleanup
    
    res.status(200).json({ 
      success: true,
      message: "Umetoka kwenye akaunti yako" 
    });
  } catch (error) {
    console.error("Logout error:", error);
    return sendErrorResponse(res, 500, "Tatizo la server wakati wa kutoka");
  }
};

// Check if a token is blacklisted (for auth middleware)
const isTokenBlacklisted = (token) => {
  return tokenBlacklist.has(token);
};

module.exports = { 
  register, 
  login,
  logout,
  isTokenBlacklisted
};