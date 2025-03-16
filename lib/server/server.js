//filename:lib/server/server.js (main node file)
require("dotenv").config();
const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const db = require("./db");

const usersRoutes = require("./users");
const itemsRoutes = require("./items");
const lendRoutes = require("./lending_transaction");
const borrowRoutes = require("./borrowing_transaction");
//const transferRoutes = require("./transfer_transaction");
const { router: notifRouter, setSocketIo } = require("./notif");

const app = express();
const server = http.createServer(app); // Create HTTP server
const io = new Server(server, { cors: { origin: "*" } }); // Initialize WebSocket

// Middleware
app.use(express.json());
app.use(cors());

// Routes
app.use("/api/users", usersRoutes);
app.use("/api/items", itemsRoutes);
app.use("/api/lendTransaction", lendRoutes);
app.use("/api/borrowTransaction", borrowRoutes);
//app.use("/api/transferTransaction", transferRoutes);
app.use("/api/notifications", notifRouter); // Notification API

// Initialize WebSocket in the notification module
setSocketIo(io);

// Start Server
const PORT = process.env.PORT || 5000; // Fallback to 5000 if PORT is undefined
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));

io.on("connection", (socket) => {
  console.log(`New user connected: ${socket.id}`);

  socket.on("joinRoom", (empId) => {
    socket.join(`emp_${empId}`);
    console.log(`User joined room: emp_${empId}`);
  });

  socket.on("disconnect", () => {
    console.log(`User disconnected: ${socket.id}`);
  });
});

