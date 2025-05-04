const express = require("express");
const cors = require("cors");
require("dotenv").config();

const userRoutes = require("./routes/userRoutes");
const cropRoutes = require("./routes/cropRoutes");
const orderRoutes = require("./routes/orderRoutes");
const chatRoutes = require("./routes/chatRoutes");
const transactionRoutes = require("./routes/transactionRoutes");
const reportRoutes = require("./routes/reportRoutes");
const settingRoutes = require("./routes/settingRoutes");
const businessRoutes = require('./routes/businessRoutes');
const cartRoutes = require('./routes/cartRoutes');

const app = express();
app.use(cors());

// Middleware to parse JSON with error handling
app.use(express.json({
  type: 'application/json',
  limit: '10mb' // Optional: Limit payload size to 10MB
}));

// Serve static files
app.use('/images', express.static('images'));

// Route setup
app.use('/api/cart', cartRoutes);
app.use("/api/users", userRoutes);
app.use("/api/crops", cropRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/settings", settingRoutes);
app.use("/api/business", businessRoutes);

// Error-handling middleware for JSON parsing errors
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    console.error('Invalid JSON payload:', err.message);
    return res.status(400).json({
      error: 'Invalid JSON format in request body',
      message: 'Please check your input and ensure it is valid JSON'
    });
  }
  next(err); // Pass other errors to the next middleware
});

// Centralized error handling for other errors
app.use((err, req, res, next) => {
  console.error('Unexpected error:', err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: 'Something broke!'
  });
});

// Server start
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});