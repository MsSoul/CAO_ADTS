const express = require("express");
const router = express.Router();
const db = require("./db");

console.log("return_transaction.js is running...");

router.post("/return", async (req, res) => {
    try {
        console.log("📥 Received return request:", req.body);

        const { borrower_emp_id, owner_emp_id, item_id, quantity, current_dpt_id, distributed_item_id } = req.body;

        const missingFields = [];
        if (!borrower_emp_id) missingFields.push("borrower_emp_id");
        if (!owner_emp_id) missingFields.push("owner_emp_id");
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

        // Fetch employee names for better notification messages
        const capitalizeName = (name) => name.toLowerCase().replace(/\b\w/g, (char) => char.toUpperCase());

        const [borrowerResult] = await db.query("SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?", [borrower_emp_id]);
        const [ownerResult] = await db.query("SELECT FIRSTNAME, LASTNAME FROM employee WHERE ID = ?", [owner_emp_id]);

        const borrowerName = borrowerResult.length > 0 ? `${capitalizeName(borrowerResult[0].FIRSTNAME)} ${capitalizeName(borrowerResult[0].LASTNAME)}` : `Employee ${borrower_emp_id}`;
        const ownerName = ownerResult.length > 0 ? `${capitalizeName(ownerResult[0].FIRSTNAME)} ${capitalizeName(ownerResult[0].LASTNAME)}` : `Employee ${owner_emp_id}`;

        // Fetch item details for notifications
        const [itemResult] = await db.query(
            `SELECT di.ID AS DISTRIBUTED_ITEM_ID, di.ITEM_ID, i.ITEM_NAME, i.DESCRIPTION 
             FROM distributed_items di
             JOIN items i ON di.ITEM_ID = i.ID
             WHERE di.ITEM_ID = ? AND di.deleted = 0`,
            [item_id]
        );

        if (itemResult.length === 0) {
            console.error(`❌ Item with ItemId=${item_id} not found`);
            return res.status(404).json({ error: "Item not found" });
        }

        const item = itemResult[0];

        // Fetch the borrowing transaction and verify correct ownership
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
        console.log(`🛠️ Found borrowing transaction ID: ${transaction.ID}, owner_emp_id=${transaction.owner_emp_id}, borrowed_qty=${transaction.quantity}`);

        if (Number(transaction.owner_emp_id) !== Number(owner_emp_id)) {
            console.error(`🚨 Owner mismatch! Transaction owner_emp_id=${transaction.owner_emp_id}, request owner_emp_id=${owner_emp_id}`);
            return res.status(400).json({ error: "Invalid owner for this item" });
        }

        if (quantity > transaction.quantity) {
            console.error(`🚨 Returned quantity (${quantity}) exceeds borrowed amount (${transaction.quantity})`);
            return res.status(400).json({ error: "Returned quantity exceeds borrowed amount" });
        }

        // Update transaction to pending return
        await db.query(
            `UPDATE borrowing_transaction 
             SET status = 2, remarks = 5, updatedAt = NOW()
             WHERE ID = ?`,
            [transaction.ID]
        );

        console.log(`✅ Transaction ID ${transaction.ID} updated to status=2 (pending return).`);

        // Notifications
        const itemDetails = `🔹 Item Details:\nItem Name: ${item.ITEM_NAME}\nDescription: ${item.DESCRIPTION}\nQuantity: ${quantity}`;

        const adminMessage = `**Subject: Return Request Submitted**\nFrom: ${borrowerName}\n\n${borrowerName} has requested to return an item to ${ownerName}.\n\n${itemDetails}`;
        const ownerMessage = `**Subject: Return Request Submitted**\nDear ${ownerName},\n\n${borrowerName} has requested to return your item.\n\n${itemDetails}`;
        const borrowerMessage = `**Subject: Return Request Confirmation**\nDear ${borrowerName},\n\nYou have submitted a return request for an item to ${ownerName}.\n\n${itemDetails}`;

        const notifications = [
            { message: adminMessage, for_emp: 1, transaction_id: transaction.ID },
            { message: ownerMessage, for_emp: owner_emp_id, transaction_id: transaction.ID },
            { message: borrowerMessage, for_emp: borrower_emp_id, transaction_id: transaction.ID }
        ];

        for (const notif of notifications) {
            await db.query(
                `INSERT INTO notification_tbl (message, for_emp, transaction_id, createdAt, updatedAt, REMARKS) 
                 VALUES (?, ?, ?, NOW(), NOW(), 1)`,
                [notif.message, notif.for_emp, notif.transaction_id]
            );
        }

        console.log(`🔔 Notifications linked to transaction ID ${transaction.ID} sent successfully!`);

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
