const express = require("express");
const router = express.Router();
const db = require("./db");

console.log("return_transaction.js is running...");

router.post("/return", async (req, res) => {
    try {
        console.log("📥 Received return request:", req.body);

        const { borrower_emp_id, item_id, quantity, current_dpt_id, distributed_item_id } = req.body;

        const missingFields = [];
        if (!borrower_emp_id) missingFields.push("borrower_emp_id");
        if (!item_id) missingFields.push("item_id");
        if (!distributed_item_id) missingFields.push("distributed_item_id");
        if (quantity === undefined || quantity === null) missingFields.push("quantity");
        if (!current_dpt_id) missingFields.push("current_dpt_id");

        if (missingFields.length > 0) {
            console.error("❗ Missing required fields:", missingFields.join(", "));
            return res.status(400).json({
                error: "Missing required fields",
                missingFields: missingFields
            });
        }

        if (typeof quantity !== 'number' || isNaN(quantity) || quantity <= 0) {
            return res.status(400).json({ error: "Invalid quantity provided" });
        }

        const [itemResult] = await db.query(
            `SELECT di.ID AS DISTRIBUTED_ITEM_ID, di.ITEM_ID
             FROM distributed_items di
             WHERE di.ITEM_ID = ? AND di.deleted = 0`,
            [item_id]
        );

        if (itemResult.length === 0) {
            console.error(`❌ Item with ItemId=${item_id} not found`);
            return res.status(404).json({ error: "Item not found" });
        }

        const item = itemResult[0];

        const [borrowedTransaction] = await db.query(
            `SELECT ID, quantity, owner_emp_id 
             FROM borrowing_transaction 
             WHERE distributed_item_id = ? AND borrower_emp_id = ? AND status = 1`,
            [distributed_item_id, borrower_emp_id]
        );

        if (borrowedTransaction.length === 0) {
            console.error(`❌ Borrowing transaction not found for distributed_item_id=${distributed_item_id}`);
            return res.status(404).json({ error: "Borrowing transaction not found" });
        }

        const transaction = borrowedTransaction[0];

        if (quantity > transaction.quantity) {
            console.error(`🚨 Returned quantity (${quantity}) exceeds borrowed amount (${transaction.quantity})`);
            return res.status(400).json({ error: "Returned quantity exceeds borrowed amount" });
        }

        // Update borrowing_transaction status to pending return
        await db.query(
            `UPDATE borrowing_transaction 
             SET status = 2, remarks = 5, updatedAt = NOW()
             WHERE ID = ?`,
            [transaction.ID]
        );

        console.log(`✅ Transaction ID ${transaction.ID} updated to status=2 (pending return).`);

        // ✅ Insert one notification record for return with TRANSACTION = 5
        await db.query(
            `INSERT INTO notification_tbl 
             (TRANSACTION_ID, TRANSACTION, ITEM_ID, QUANTITY, REQUEST_STATUS, OWNER_ID, BORROWER_ID, ADMIN_ID, createdAt, updatedAt, \`READ\`) 
             VALUES (?, 5, ?, ?, 2, ?, ?, 1, NOW(), NOW(), 0)`,
            [
                transaction.ID,        // TRANSACTION_ID
                item.ITEM_ID,          // ITEM_ID
                quantity,              // QUANTITY
                transaction.owner_emp_id, // OWNER_ID
                borrower_emp_id        // BORROWER_ID
            ]
        );

        console.log(`🔔 Return notification (TRANSACTION=5) for transaction ID ${transaction.ID} saved successfully!`);

        res.status(200).json({
            message: "Return request submitted successfully!",
            transactionId: transaction.ID
        });

    } catch (error) {
        console.error("❌ Error processing return request:", error);
        res.status(500).json({ error: "Server error" });
    }
});


module.exports = router;
