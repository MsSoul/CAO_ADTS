//filaname: lib/server/lending_transaction.js
const express = require("express");
const router = express.Router();
const db = require("./db");

console.log("lending_transaction.js is running...");

// Fetch borrowers based on current department ID
router.get("/borrowers", async (req, res) => {
    try {
        const { current_dpt_id, query, search_type, emp_id } = req.query;
        console.log("🔍 Received Request:", req.query);

        if (!current_dpt_id || !emp_id) {
            return res.status(400).json({ message: "Missing required parameters" });
        }

        let sqlQuery = `
        SELECT ID AS borrowerId, ID_NUMBER, FIRSTNAME, MIDDLENAME, LASTNAME, SUFFIX 
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

        const [borrowers] = await db.query(sqlQuery, params);

        if (borrowers.length === 0) {
            return res.status(404).json({ message: "No borrowers found" });
        }

        console.log("📦 Borrowers Retrieved:", borrowers);
        res.json(borrowers);
    } catch (error) {
        console.error("❌ Error fetching borrowers:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});


router.post("/lend_transaction", async (req, res) => {
    try {
        const { emp_id, itemId, quantity, borrowerId, currentDptId } = req.body;
        console.log("📩 Received Lending Request:", req.body);

        if (!emp_id || !itemId || !borrowerId || !quantity || !currentDptId) {
            return res.status(400).json({ message: "Missing required parameters" });
        }

        // Function to capitalize first letter of each word
        const capitalizeName = (name) => {
            return name.toLowerCase().replace(/\b\w/g, (char) => char.toUpperCase());
        };

        // Fetch employee and borrower names
        const [empResult] = await db.query(`SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?`, [emp_id]);
        const [borrowerResult] = await db.query(`SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?`, [borrowerId]);

        const empName = empResult.length > 0 ? `${capitalizeName(empResult[0].FIRSTNAME)} ${capitalizeName(empResult[0].LASTNAME)}`.trim() : `Employee ${emp_id}`;
        const borrowerName = borrowerResult.length > 0 ? `${capitalizeName(borrowerResult[0].FIRSTNAME)} ${capitalizeName(borrowerResult[0].LASTNAME)}`.trim() : `Borrower ${borrowerId}`;

        // Insert into lending transaction table
        const [result] = await db.query(
            `INSERT INTO borrowing_transaction 
             (distributed_item_id, borrower_emp_id, owner_emp_id, quantity, status, createdAt, updatedAt, DPT_ID, remarks) 
             VALUES (?, ?, ?, ?, 2, NOW(), NOW(), ?, 2)`,
            [itemId, borrowerId, emp_id, quantity, currentDptId]
        );

        const transactionId = result.insertId;
        console.log(`🎉 Lend Transaction Submitted Successfully! Transaction ID: ${transactionId}`);

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
        const adminMessage = `**Subject: Lending Item Request**\nFrom: ${empName}\n\nDear Admin,\n\n${empName} has initiated a lending transaction for Mr./Mrs. ${borrowerName}.\n\n🔹 **Transaction Details:**\nItem Name: ${item.ITEM_NAME}\nDescription: ${item.DESCRIPTION}\nQuantity: ${quantity}\nPAR No.: ${item.PAR_NO}\nMR No.: ${item.MR_NO}\nPIS No.: ${item.PIS_NO}\nProperty No.: ${item.PROP_NO}\nSerial No.: ${item.SERIAL_NO}\nUnit Value: ${item.unit_value}\nTotal Value: ${item.total_value}`;

        const borrowerMessage = `**Subject: Request to Lend Item**\nFrom: ${empName}\n\nDear ${borrowerName},\n\nMr./Mrs. ${empName} has requested to lend an item to you.\n\n🔹 Transaction Details:\nItem Name: ${item.ITEM_NAME}\nDescription: ${item.DESCRIPTION}\nQuantity: ${quantity}\nPAR No.: ${item.PAR_NO}\nMR No.: ${item.MR_NO}\nPIS No.: ${item.PIS_NO}\nProperty No.: ${item.PROP_NO}\nSerial No.: ${item.SERIAL_NO}\nUnit Value: ${item.unit_value}\nTotal Value: ${item.total_value}\n\nPlease review the details and proceed accordingly.`;

        const requesterMessage = `**Lending Request Submitted**\nDear ${empName},\n\nYour request to borrow this item has been successfully submitted.\n\n🔹 Item Details:\nItem Name: ${item.ITEM_NAME}\nDescription: ${item.DESCRIPTION}\nQuantity: ${quantity}\nPAR No.: ${item.PAR_NO}\nMR No.: ${item.MR_NO}\nPIS No.: ${item.PIS_NO}\nProperty No.: ${item.PROP_NO}\nSerial No.: ${item.SERIAL_NO}\nUnit Value: ${item.unit_value}\nTotal Value: ${item.total_value}\n\nYou will be notified once the admin reviews your request.`;

        // ✅ Save Notifications
        const notifications = [
            { message: adminMessage, for_emp: 1, transaction_id: transactionId },
            { message: borrowerMessage, for_emp: borrowerId, transaction_id: transactionId },
            { message: requesterMessage, for_emp: emp_id, transaction_id: transactionId }
        ];

        for (let notif of notifications) {
            await db.query(
                `INSERT INTO notification_tbl (message, for_emp, transaction_id, createdAt, updatedAt, REMARKS) 
                 VALUES (?, ?, ?, NOW(), NOW(), 2)`,
                [notif.message, notif.for_emp, notif.transaction_id]
            );
        }

        console.log("🔔 Notifications saved successfully!");

        // ✅ Simplified Response
        res.status(201).json({
            message: "Request submitted successfully!",
            transactionId: transactionId
        });

    } catch (error) {
        console.error("❌ Error submitting transaction:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

module.exports = router;
