
const express = require("express");
const router = express.Router();
const db = require("./db");

console.log("lending_transaction.js is running...");


router.get("/receivers", async (req, res) => {
    try {
        const { current_dpt_id, query, search_type, emp_id } = req.query;
        console.log("🔍 Received Request for Receivers:", req.query);

        if (!current_dpt_id || !emp_id) {
            return res.status(400).json({ message: "Missing required parameters" });
        }

        let sqlQuery = `
        SELECT ID AS receiverId, ID_NUMBER, FIRSTNAME, MIDDLENAME, LASTNAME, SUFFIX 
        FROM employee 
        WHERE CURRENT_DPT_ID = ? 
        AND ID != ?`;

        let params = [current_dpt_id, emp_id];

        if (query) {
            if (search_type === "ID Number") {
                sqlQuery += " AND ID_NUMBER LIKE ?";
                params.push(`%${query}%`);
            } else {
                sqlQuery += " AND CONCAT(FIRSTNAME, ' ', LASTNAME) LIKE ?";
                params.push(`%${query}%`);
            }
        }

        console.log("📢 Executing SQL Query:", sqlQuery, "Params:", params);

        const [receivers] = await db.query(sqlQuery, params);

        if (receivers.length === 0) {
            return res.status(404).json({ message: "No receivers found" });
        }

        console.log("📦 Receivers Retrieved:", receivers);
        res.json(receivers);
    } catch (error) {
        console.error("❌ Error fetching receivers:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});


router.post("/transfer_Transaction", async (req, res) => {
    try {
        const { emp_id, itemId, quantity, receiverId, currentDptId, distributedItemId } = req.body;
        console.log("📩 Received Transfer Request:", req.body);

        if (!emp_id || !itemId || !receiverId || !quantity || !currentDptId) {
            return res.status(400).json({ message: "Missing required parameters" });
        }

        // Function to capitalize first letter of each word
        const capitalizeName = (name) => {
            return name.toLowerCase().replace(/\b\w/g, (char) => char.toUpperCase());
        };

        // Fetch sender and receiver names
        const [senderResult] = await db.query(`SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?`, [emp_id]);
        const [receiverResult] = await db.query(`SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?`, [receiverId]);

        const senderName = senderResult.length > 0 ? `${capitalizeName(senderResult[0].FIRSTNAME)} ${capitalizeName(senderResult[0].LASTNAME)}`.trim() : `Employee ${emp_id}`;
        const receiverName = receiverResult.length > 0 ? `${capitalizeName(receiverResult[0].FIRSTNAME)} ${capitalizeName(receiverResult[0].LASTNAME)}`.trim() : `Receiver ${receiverId}`;

        // Insert into borrowing_transaction table with remarks=4 (transfer)
        const [result] = await db.query(
            `INSERT INTO borrowing_transaction 
             (DISTRIBUTED_ITM_ID,distributed_item_id, borrower_emp_id, owner_emp_id, quantity, status, createdAt, updatedAt, DPT_ID, remarks) 
             VALUES (?,?, ?, ?, ?, 2, NOW(), NOW(), ?, 4)`,
            [distributedItemId, itemId, receiverId, emp_id, quantity, currentDptId]
        );

        const transactionId = result.insertId;
        console.log(`🎉 Transfer Transaction Submitted Successfully! Transaction ID: ${transactionId}`);

        // Fetch detailed item information
        const [itemResult] = await db.query(
            `SELECT 
                di.ID AS DISTRIBUTED_ITEM_ID,
                di.ITEM_ID,
                di.accountable_emp AS OWNER_EMP_ID,
                di.quantity,  
                di.original_quantity AS ORIGINAL_QUANTITY,
                di.remarks,
                i.PAR_NO, 
                i.MR_NO, 
                i.PIS_NO, 
                i.PROP_NO, 
                i.SERIAL_NO,
                i.unit_value,
                i.total_value,
                i.ITEM_NAME,  
                i.DESCRIPTION 
            FROM distributed_items di
            JOIN items i ON di.ITEM_ID = i.ID
            WHERE di.ITEM_ID = ? AND di.deleted = 0`,
            [itemId]
        );

        if (itemResult.length === 0) {
            return res.status(404).json({ message: "Item not found" });
        }

        const item = itemResult[0];

        // ✅ Create Notification Messages
        const adminMessage = `**Subject: Item Transfer Request**\nFrom: ${senderName}\n\nDear Admin,\n\n${senderName} has initiated a transfer transaction to Mr./Mrs. ${receiverName}.\n\n🔹 **Transaction Details:**\nItem Name: ${item.ITEM_NAME}\nDescription: ${item.DESCRIPTION}\nQuantity: ${quantity}\nPAR No.: ${item.PAR_NO}\nMR No.: ${item.MR_NO}\nPIS No.: ${item.PIS_NO}\nProperty No.: ${item.PROP_NO}\nSerial No.: ${item.SERIAL_NO}\nUnit Value: ${item.unit_value}\nTotal Value: ${item.total_value}`;

        const receiverMessage = `**Subject: Item Transfer Notice**\nFrom: ${senderName}\n\nDear ${receiverName},\n\nMr./Mrs. ${senderName} has transferred an item to you.\n\n🔹 **Transaction Details:**\nItem Name: ${item.ITEM_NAME}\nDescription: ${item.DESCRIPTION}\nQuantity: ${quantity}\nPAR No.: ${item.PAR_NO}\nMR No.: ${item.MR_NO}\nPIS No.: ${item.PIS_NO}\nProperty No.: ${item.PROP_NO}\nSerial No.: ${item.SERIAL_NO}\nUnit Value: ${item.unit_value}\nTotal Value: ${item.total_value}\n\nPlease confirm receipt of the item.`;

        const senderMessage = `**Transfer Request Submitted**\nDear ${senderName},\n\nYour request to transfer this item has been successfully submitted.\n\n🔹 **Item Details:**\nItem Name: ${item.ITEM_NAME}\nDescription: ${item.DESCRIPTION}\nQuantity: ${quantity}\nPAR No.: ${item.PAR_NO}\nMR No.: ${item.MR_NO}\nPIS No.: ${item.PIS_NO}\nProperty No.: ${item.PROP_NO}\nSerial No.: ${item.SERIAL_NO}\nUnit Value: ${item.unit_value}\nTotal Value: ${item.total_value}\n\nYou will be notified once the receiver acknowledges the transfer.`;

        // ✅ Save Notifications
        const notifications = [
            { message: adminMessage, for_emp: 1, transaction_id: transactionId },
            { message: receiverMessage, for_emp: receiverId, transaction_id: transactionId },
            { message: senderMessage, for_emp: emp_id, transaction_id: transactionId }
        ];

        for (let notif of notifications) {
            await db.query(
                `INSERT INTO notification_tbl (message, for_emp, transaction_id, createdAt, updatedAt, REMARKS) 
                 VALUES (?, ?, ?, NOW(), NOW(), 4)`,
                [notif.message, notif.for_emp, notif.transaction_id]
            );
        }

        console.log("🔔 Notifications saved successfully!");

        // ✅ Simplified Response
        res.status(201).json({
            message: "Transfer request submitted successfully!",
            transactionId: transactionId
        });

    } catch (error) {
        console.error("❌ Error submitting transfer transaction:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});



module.exports = router;
