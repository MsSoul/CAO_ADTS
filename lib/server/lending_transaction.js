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
        const { emp_id, itemId, quantity, borrowerId, currentDptId, distributedItemId } = req.body;
        console.log("📩 Received Lending Request:", req.body);

        if (!emp_id || !itemId || !borrowerId || !quantity || !currentDptId) {
            return res.status(400).json({ message: "Missing required parameters" });
        }

        // Insert into borrowing_transaction table as a lending record
        const [result] = await db.query(
            `INSERT INTO borrowing_transaction 
             (DISTRIBUTED_ITM_ID, distributed_item_id, borrower_emp_id, owner_emp_id, quantity, status, createdAt, updatedAt, DPT_ID, remarks) 
             VALUES (?, ?, ?, ?, ?, 2, NOW(), NOW(), ?, 2)`,
            [distributedItemId, itemId, borrowerId, emp_id, quantity, currentDptId]
        );

        const transactionId = result.insertId;
        console.log(`🎉 Lend Transaction Submitted Successfully! Transaction ID: ${transactionId}`);

        // Fetch item details
        const [itemResult] = await db.query(
            `SELECT 
                di.ITEM_ID
            FROM distributed_items di
            WHERE di.ITEM_ID = ? AND di.deleted = 0`,
            [itemId]
        );

        if (itemResult.length === 0) {
            return res.status(404).json({ message: "Item not found" });
        }

        const item = itemResult[0];

        // ✅ Save single notification record for lending transaction
        await db.query(
            `INSERT INTO notification_tbl 
             (TRANSACTION_ID, TRANSACTION, ITEM_ID, QUANTITY, REQUEST_STATUS, OWNER_ID, BORROWER_ID, ADMIN_ID, createdAt, updatedAt, \`READ\`) 
             VALUES (?, 2, ?, ?, 2, ?, ?, 1, NOW(), NOW(), 0)`,
            [
                transactionId,  // TRANSACTION_ID
                item.ITEM_ID,   // ITEM_ID
                quantity,       // QUANTITY
                emp_id,         // OWNER_ID (the lender)
                borrowerId      // BORROWER_ID
            ]
        );

        console.log("🔔 Lending notification saved successfully!");

        // ✅ Response
        res.status(201).json({
            message: "Lending request submitted successfully!",
            transactionId: transactionId
        });

    } catch (error) {
        console.error("❌ Error submitting lending transaction:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

module.exports = router;
