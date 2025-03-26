
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

        if (!emp_id || !itemId || !receiverId || !quantity || !currentDptId || !distributedItemId) {
            return res.status(400).json({ message: "Missing required parameters" });
        }

        const capitalizeName = (name) =>
            name.toLowerCase().replace(/\b\w/g, (char) => char.toUpperCase());

        // Fetch sender and receiver names
        const [senderResult] = await db.query(
            `SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?`,
            [emp_id]
        );
        const [receiverResult] = await db.query(
            `SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?`,
            [receiverId]
        );

        const senderName = senderResult.length > 0
            ? `${capitalizeName(senderResult[0].FIRSTNAME)} ${capitalizeName(senderResult[0].LASTNAME)}`.trim()
            : `Employee ${emp_id}`;

        const receiverName = receiverResult.length > 0
            ? `${capitalizeName(receiverResult[0].FIRSTNAME)} ${capitalizeName(receiverResult[0].LASTNAME)}`.trim()
            : `Receiver ${receiverId}`;

        // Insert into borrowing_transaction table with remarks=4 (transfer)
        const [result] = await db.query(
            `INSERT INTO borrowing_transaction 
            (DISTRIBUTED_ITM_ID, distributed_item_id, borrower_emp_id, owner_emp_id, quantity, status, createdAt, updatedAt, DPT_ID, remarks) 
            VALUES (?, ?, ?, ?, ?, 2, NOW(), NOW(), ?, 4)`,
            [distributedItemId, itemId, receiverId, emp_id, quantity, currentDptId]
        );

        const transactionId = result.insertId;
        console.log(`🎉 Transfer Transaction (ID: ${transactionId}) submitted successfully!`);

        // Fetch item details
        const [itemResult] = await db.query(
            `SELECT 
                di.ID AS DISTRIBUTED_ITEM_ID,
                di.ITEM_ID,
                i.PAR_NO, i.MR_NO, i.PIS_NO, i.PROP_NO, i.SERIAL_NO,
                i.unit_value, i.total_value,
                i.ITEM_NAME, i.DESCRIPTION 
            FROM distributed_items di
            JOIN items i ON di.ITEM_ID = i.ID
            WHERE di.ITEM_ID = ? AND di.deleted = 0`,
            [itemId]
        );

        if (itemResult.length === 0) {
            return res.status(404).json({ message: "Item not found" });
        }

        const item = itemResult[0];

        // ✅ Insert one row in notification_tbl with TRANSACTION = 4 (transfer)
        await db.query(
            `INSERT INTO notification_tbl 
             (TRANSACTION_ID, TRANSACTION, ITEM_ID, QUANTITY, REQUEST_STATUS, OWNER_ID, BORROWER_ID, ADMIN_ID, createdAt, updatedAt, \`READ\`) 
             VALUES (?, 4, ?, ?, 2, ?, ?, 1, NOW(), NOW(), 0)`,
            [
                transactionId,
                item.ITEM_ID,
                quantity,
                emp_id,      // sender (owner)
                receiverId   // borrower (receiver)
            ]
        );

        console.log("🔔 Transfer notification (TRANSACTION=4) saved successfully!");

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
