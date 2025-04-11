const express = require('express');
const { register, login } = require("../controllers/authController");
const router = express.Router();

router.post("/register", register);
router.post("/login", login);

module.exports = router;
// This code defines the routes for user authentication, including registration and login.


// const express = require("express");
// const { register, login, logout } = require("../controllers/authController");
// const { auth } = require("../middleware/auth"); // Import auth middleware
// const router = express.Router();

// // Public routes - no authentication required
// router.post("/register", register); // Route for user registration
// router.post("/login", login);       // Route for user login

// // Protected routes - require authentication
// router.post("/logout", auth, logout); // Route for user logout

// // Route to verify token (used by frontend to check if user is still logged in)
// router.get("/verify-token", auth, (req, res) => {
//   try {
//     // If middleware passes, token is valid
//     res.status(200).json({
//       valid: true,
//       user: {
//         id: req.user.id, // Ensure this matches the decoded token structure
//         email: req.user.email, // Ensure this matches the token payload
//       },
//     });
//   } catch (error) {
//     console.error("Error verifying token:", error);
//     res.status(500).json({ message: "Server error during token verification" });
//   }
// });

// // Route to refresh token (optional - implement if needed)
// // Uncomment and implement if you need token refresh functionality
// // router.post("/refresh-token", refreshToken);

// module.exports = router;