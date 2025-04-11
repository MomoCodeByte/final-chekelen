// const express = require('express');
const express = require("express");
const cors = require("cors");
require("dotenv").config(); // Load environment variables

const userRoutes = require("./routes/userRoutes");
const cropRoutes = require("./routes/cropRoutes");
const orderRoutes = require("./routes/orderRoutes");
const chatRoutes = require("./routes/chatRoutes");
const transactionRoutes = require("./routes/transactionRoutes");
const reportRoutes = require("./routes/reportRoutes");
const settingRoutes = require("./routes/settingRoutes");

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/users", userRoutes);
app.use("/api/crops", cropRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/transactions", transactionRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/settings", settingRoutes);

const PORT = process.env.PORT || 3000;
// const HOST = process.env.HOST || "192.168.1.103"; // Default to '0.0.0.0' to allow external access

// app.listen(PORT, HOST, () => {
//   console.log(`Server running on http://${HOST}:${PORT}`);
// });

app.listen(PORT, () => {
  console.log("Server Run Under Ports:", PORT);
});
