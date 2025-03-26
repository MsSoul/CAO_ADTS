//filename:lib/server/notif.js
const express = require("express");
const db = require("./db");

const router = express.Router();

console.log("notif.js is running...");

// WebSocket instance (to be initialized in main server)
let io;
const setSocketIo = (socketIo) => {
  if (!io) {
    io = socketIo;
    console.log("✅ WebSocket initialized!");

    io.on("connection", (socket) => {
      console.log("🔗 User connected:", socket.id);

      socket.on("joinRoom", (empId) => {
        socket.join(`emp_${empId}`);
        console.log(`👥 User joined room: emp_${empId}`);
      });

      socket.on("disconnect", () => {
        console.log("❌ User disconnected:", socket.id);
      });
    });
  } else {
    console.log("⚠️ WebSocket already initialized!");
  }
};


// Fetch unread notifications for an employee with item details
router.get("/:empId", async (req, res) => {
  const empId = parseInt(req.params.empId, 10);

  if (isNaN(empId)) {
    return res.status(400).json({ error: "Invalid employee ID" });
  }

  try {
    const [notifications] = await db.query(
      `SELECT 
        n.ID, 
        n.\`READ\`, 
        n.TRANSACTION_ID, 
        n.ITEM_ID,
        n.QUANTITY,
        DATE_FORMAT(n.createdAt, '%Y-%m-%dT%H:%i:%sZ') AS createdAt,
        i.PAR_NO, 
        i.MR_NO, 
        i.PIS_NO, 
        i.PROP_NO, 
        i.SERIAL_NO, 
        i.unit_value, 
        i.total_value, 
        i.ITEM_NAME, 
        i.DESCRIPTION,
        n.TRANSACTION AS transaction_type,   
        n.REQUEST_STATUS AS request_status,  
        CONCAT(borrower_emp.FIRSTNAME, ' ', borrower_emp.LASTNAME) AS borrower_name,
        CONCAT(owner_emp.FIRSTNAME, ' ', owner_emp.LASTNAME) AS owner_name
      FROM notification_tbl n
      LEFT JOIN items i ON n.ITEM_ID = i.ID
      LEFT JOIN borrowing_transaction t ON n.TRANSACTION_ID = t.ID
      LEFT JOIN employee borrower_emp ON n.BORROWER_ID = borrower_emp.ID
      LEFT JOIN employee owner_emp ON n.OWNER_ID = owner_emp.ID
      ORDER BY n.\`READ\` ASC, n.createdAt DESC`
    );
    
    
    res.json(notifications);
  } catch (err) {
    console.error("Error fetching notifications with item details:", err);
    res.status(500).json({ error: err.message });
  }
});


// Mark notification as read
router.put("/mark_as_read/:notifId", async (req, res) => {
  console.log("📥 Received request:", req.params); // Debugging log
  const { notifId } = req.params;

  if (!notifId) {
    return res.status(400).json({ message: "Missing notification ID" });
  }

  const [result] = await db.query(
    "UPDATE notification_tbl SET `READ` = 1 WHERE ID = ?", 
    [notifId]
  );

  if (result.affectedRows === 0) {
    return res.status(404).json({ message: "Notification not found" });
  }

  console.log(`✅ Notification ID ${notifId} marked as read`);
  res.status(200).json({ message: "Notification marked as read" });
});

const sendNotification = async (notification) => {
  if (io) {
    console.log(`📢 Sending notification to emp_${notification.for_emp}:`, notification);
    io.to(`emp_${notification.for_emp}`).emit("newNotification", notification);
  } else {
    console.log("❌ WebSocket (io) is NOT initialized!");
  }
};

// Export router & WebSocket setup
module.exports = { router, setSocketIo, sendNotification };
